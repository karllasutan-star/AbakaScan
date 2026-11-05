from dataclasses import dataclass
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageOps, UnidentifiedImageError


# ============================================================
# IMAGE RULES
# ============================================================

MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024

SUPPORTED_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
}

SUPPORTED_FORMATS = {
    "JPEG": "image/jpeg",
    "PNG": "image/png",
}


# ============================================================
# VALIDATED IMAGE
# ============================================================

@dataclass
class ValidatedImage:
    image: Image.Image
    image_bytes: bytes
    file_name: str
    mime_type: str
    width: int
    height: int


# ============================================================
# VALIDATION ERROR
# ============================================================

class ImageValidationError(ValueError):
    pass


# ============================================================
# VALIDATE IMAGE
# ============================================================

def validate_image(
    image_bytes: bytes,
    file_name: str,
    content_type: str | None = None,
) -> ValidatedImage:
    if not image_bytes:
        raise ImageValidationError(
            "The uploaded image is empty."
        )

    if len(image_bytes) > MAX_IMAGE_SIZE_BYTES:
        raise ImageValidationError(
            "The uploaded image is too large. "
            "Maximum file size is 10 MB."
        )

    normalized_file_name = Path(
        file_name or "uploaded_image"
    ).name

    extension = Path(
        normalized_file_name
    ).suffix.lower()

    if extension not in SUPPORTED_EXTENSIONS:
        raise ImageValidationError(
            "Unsupported image format. "
            "Please upload a JPG, JPEG, or PNG image."
        )

    if content_type is not None:
        normalized_content_type = (
            content_type
            .split(";")[0]
            .strip()
            .lower()
        )

        allowed_content_types = {
            "image/jpeg",
            "image/jpg",
            "image/png",
            "application/octet-stream",
        }

        if (
            normalized_content_type
            and normalized_content_type
            not in allowed_content_types
        ):
            raise ImageValidationError(
                "The uploaded file is not a supported image."
            )

    try:
        # First pass verifies that Pillow can actually decode
        # the uploaded file.
        with Image.open(
            BytesIO(image_bytes)
        ) as verification_image:
            verification_image.verify()

        # Reopen after verify(), because verify() must not be
        # followed by normal image operations on the same object.
        with Image.open(
            BytesIO(image_bytes)
        ) as opened_image:
            detected_format = (
                opened_image.format or ""
            ).upper()

            if detected_format not in SUPPORTED_FORMATS:
                raise ImageValidationError(
                    "Unsupported image format. "
                    "Please upload a JPG, JPEG, or PNG image."
                )

            image = ImageOps.exif_transpose(
                opened_image
            )

            if image.width <= 0 or image.height <= 0:
                raise ImageValidationError(
                    "The uploaded image has invalid dimensions."
                )

            # ABAKASCAN will use RGB images for the
            # classification pipeline.
            if image.mode in (
                "RGBA",
                "LA",
            ):
                rgba_image = image.convert("RGBA")

                background = Image.new(
                    "RGB",
                    rgba_image.size,
                    (255, 255, 255),
                )

                background.paste(
                    rgba_image,
                    mask=rgba_image.getchannel("A"),
                )

                processed_image = background

            else:
                processed_image = image.convert(
                    "RGB"
                )

            processed_image.load()

            width = processed_image.width
            height = processed_image.height

            final_image = processed_image.copy()

    except ImageValidationError:
        raise

    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
        Image.DecompressionBombError,
    ) as error:
        raise ImageValidationError(
            "The uploaded file is not a valid readable image."
        ) from error

    detected_mime_type = SUPPORTED_FORMATS[
        detected_format
    ]

    return ValidatedImage(
        image=final_image,
        image_bytes=image_bytes,
        file_name=normalized_file_name,
        mime_type=detected_mime_type,
        width=width,
        height=height,
    )