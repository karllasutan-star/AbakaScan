from app.services.classification_service import (
    create_classification_record,
    delete_classification_record,
    get_user_classification,
    get_user_classifications,
)

from app.services.inference_service import (
    ModelNotReadyError,
    predict_abaca_grade,
)

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Response,
    UploadFile,
    status,
)
from sqlalchemy.orm import Session

from app.core.auth import get_current_user
from app.database.database import get_db
from app.models.user import User
from app.schemas.classification import (
    ClassificationRecordResponse,
    ClassificationResponse,
)
from app.services.classification_service import (
    delete_classification_record,
    get_user_classification,
    get_user_classifications,
)
from app.services.image_service import (
    ImageValidationError,
    validate_image,
)


router = APIRouter(
    prefix="/classifications",
    tags=["Classifications"],
)


# ============================================================
# AUTHORIZATION
# ============================================================

def require_regular_user(
    current_user: User,
) -> None:
    if current_user.role.upper() != "USER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Only regular ABAKASCAN users can "
                "perform classification operations."
            ),
        )


# ============================================================
# BUILD API RESPONSE
# ============================================================

def build_record_response(
    record,
) -> ClassificationRecordResponse:
    return ClassificationRecordResponse(
        classification_id=record.classification_id,
        predicted_grade=record.predicted_grade,
        confidence=record.confidence,
        created_at=record.created_at,
        image_url=(
            f"/classifications/"
            f"{record.classification_id}/image"
        ),
        model_name=record.model_name,
    )


# ============================================================
# UPLOAD + CLASSIFY
# ============================================================

@router.post(
    "",
    response_model=ClassificationResponse,
    status_code=status.HTTP_200_OK,
)
async def classify_image(
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_regular_user(
        current_user,
    )

    image_bytes = await image.read()

    try:
        validated_image = validate_image(
            image_bytes=image_bytes,
            file_name=(
                image.filename
                or "uploaded_image"
            ),
            content_type=image.content_type,
        )

    except ImageValidationError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error

    # ========================================================
    # MODEL INFERENCE
    # ========================================================

    try:
        prediction = predict_abaca_grade(
            validated_image.image,
        )

    except ModelNotReadyError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error

    # ========================================================
    # SAVE CLASSIFICATION
    # ========================================================

    try:
        record = create_classification_record(
            db=db,
            user_id=current_user.user_id,
            predicted_grade=prediction.predicted_grade,
            confidence=prediction.confidence,
            validated_image=validated_image,
            model_name=prediction.model_name,
        )

    except Exception as error:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "Unable to save the "
                "classification result."
            ),
        ) from error

    # ========================================================
    # RESPONSE
    # ========================================================

    return ClassificationResponse(
        classification_id=record.classification_id,
        predicted_grade=record.predicted_grade,
        confidence=record.confidence,
        created_at=record.created_at,
        image_url=(
            f"/classifications/"
            f"{record.classification_id}/image"
        ),
        saved_to_history=True,
        model_name=record.model_name,
    )

# ============================================================
# CLASSIFICATION HISTORY
# ============================================================

@router.get(
    "",
    response_model=list[ClassificationRecordResponse],
)
def get_classification_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_regular_user(
        current_user,
    )

    records = get_user_classifications(
        db=db,
        user_id=current_user.user_id,
    )

    return [
        build_record_response(record)
        for record in records
    ]


# ============================================================
# CLASSIFICATION DETAILS
# ============================================================

@router.get(
    "/{classification_id}",
    response_model=ClassificationRecordResponse,
)
def get_classification_details(
    classification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_regular_user(
        current_user,
    )

    record = get_user_classification(
        db=db,
        user_id=current_user.user_id,
        classification_id=classification_id,
    )

    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Classification record not found.",
        )

    return build_record_response(
        record,
    )


# ============================================================
# CLASSIFICATION IMAGE
# ============================================================

@router.get(
    "/{classification_id}/image",
)
def get_classification_image(
    classification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_regular_user(
        current_user,
    )

    record = get_user_classification(
        db=db,
        user_id=current_user.user_id,
        classification_id=classification_id,
    )

    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Classification record not found.",
        )

    if not record.image_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Image for this classification "
                "is not available."
            ),
        )

    return Response(
        content=record.image_data,
        media_type=(
            record.image_mime_type
            or "application/octet-stream"
        ),
    )


# ============================================================
# DELETE CLASSIFICATION
# ============================================================

@router.delete(
    "/{classification_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_classification(
    classification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    require_regular_user(
        current_user,
    )

    record = get_user_classification(
        db=db,
        user_id=current_user.user_id,
        classification_id=classification_id,
    )

    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Classification record not found.",
        )

    try:
        delete_classification_record(
            db=db,
            record=record,
        )

    except Exception as error:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "Unable to delete the "
                "classification record."
            ),
        ) from error

    return Response(
        status_code=status.HTTP_204_NO_CONTENT,
    )