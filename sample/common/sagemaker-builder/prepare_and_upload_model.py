
import os
import sys
import json
import tarfile
import shutil
import argparse
from pathlib import Path
import boto3
from huggingface_hub import snapshot_download
from botocore.exceptions import ClientError


class ModelPreparer:
    def __init__(self, model_id: str, output_dir: str = "./model_artifacts", model_name: str = None):
        self.model_id = model_id
        self.output_dir = Path(output_dir)
        self.model_name = model_name or self._extract_model_name(model_id)
        self.model_dir = self.output_dir / self.model_name
        self.archive_path = self.output_dir / f"{self.model_name}.tar.gz"

    def _extract_model_name(self, model_id: str) -> str:
        """Extract a clean model name from the Hugging Face model ID"""
        name = model_id.split('/')[-1].lower()
        name = name.replace('-instruct', '')
        return name

    def download_model(self):
        """Download model from Hugging Face"""
        print(f"📥 Downloading {self.model_id} from Hugging Face...")
        print("This may take a while depending on your internet connection...")

        try:
            self.model_dir.mkdir(parents=True, exist_ok=True)

            snapshot_download(
                repo_id=self.model_id,
                local_dir=str(self.model_dir),
                local_dir_use_symlinks=False,
                resume_download=True,
                ignore_patterns=["*.md", "*.txt", ".gitattributes"]
            )

            print(f"✅ Model downloaded to {self.model_dir}")
            return True

        except Exception as e:
            print(f"❌ Error downloading model: {e}")
            return False

    def create_serving_properties(self):
        """Create serving.properties file for LMI deployment"""
        print("📝 Skipping serving.properties creation...")
        print("   Configuration is managed via Terraform environment variables")


        return True

    def download_tiktoken_encodings(self):
        """Download tiktoken encodings to be bundled with the model"""
        print("📥 Downloading tiktoken encodings...")

        try:
            import tiktoken

            # Create cache directory
            cache_dir = self.model_dir / ".tiktoken_cache"
            cache_dir.mkdir(parents=True, exist_ok=True)

            # Set the cache directory for tiktoken
            os.environ['TIKTOKEN_CACHE_DIR'] = str(cache_dir)

            # Download common encodings used by models
            encodings_to_download = [
                'cl100k_base',  # GPT-4, GPT-3.5-turbo
                'o200k_base',   # GPT-4o
                'p50k_base',    # GPT-3 (davinci)
                'r50k_base',    # GPT-3 (ada, babbage, curie)
            ]

            for encoding_name in encodings_to_download:
                try:
                    print(f"  Downloading {encoding_name}...")
                    tiktoken.get_encoding(encoding_name)
                    print(f"  ✅ {encoding_name}")
                except Exception as e:
                    print(f"  ⚠️  Failed to download {encoding_name}: {e}")

            print(f"✅ Tiktoken encodings downloaded to {cache_dir}")
            return True

        except ImportError:
            print("⚠️  tiktoken not installed, skipping encoding download")
            print("   Install with: pip install tiktoken")
            return True  # Non-fatal, continue without encodings
        except Exception as e:
            print(f"⚠️  Warning: Could not download tiktoken encodings: {e}")
            return True  # Non-fatal, continue without encodings

    def create_model_metadata(self):
        """Create metadata file with model information"""
        print("📝 Creating model metadata...")

        metadata = {
            "model_id": self.model_id,
            "model_type": "vision-language",
            "framework": "pytorch",
            "architecture": "Qwen2.5-VL",
            "task": "image-text-to-text",
            "deployment_framework": "LMI-vLLM",
            "recommended_instance_type": "ml.g5.xlarge",
            "tensor_parallel_degree": 1,
            "quantization": "bitsandbytes-8bit"
        }

        metadata_path = self.model_dir / "model_metadata.json"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)

        print(f"✅ Created metadata at {metadata_path}")
        return True

    def create_tarball(self):
        """Create tar.gz archive of model artifacts"""
        print("📦 Creating model.tar.gz archive...")

        try:
            if self.archive_path.exists():
                size_mb = self.archive_path.stat().st_size / (1024 * 1024)
                print(f"✅ Archive already exists: {self.archive_path} ({size_mb:.2f} MB)")
                print("⏭️  Skipping compression step")
                return True

            with tarfile.open(self.archive_path, "w:gz") as tar:
                for item in self.model_dir.rglob("*"):
                    if item.is_file():
                        arcname = item.relative_to(self.model_dir)
                        tar.add(item, arcname=arcname)
                        print(f"  Adding: {arcname}")

            size_mb = self.archive_path.stat().st_size / (1024 * 1024)
            print(f"✅ Created archive: {self.archive_path} ({size_mb:.2f} MB)")
            return True

        except Exception as e:
            print(f"❌ Error creating archive: {e}")
            return False

    def upload_to_s3(self, bucket_name: str, s3_key: str = None, region: str = "us-east-1"):
        """Upload model archive to S3"""
        if s3_key is None:
            s3_key = f"{self.model_name}/model.tar.gz"

        print(f"☁️  Uploading to S3: s3://{bucket_name}/{s3_key}")

        try:
            s3_client = boto3.client('s3', region_name=region)

            try:
                s3_client.head_bucket(Bucket=bucket_name)
            except ClientError:
                print(f"❌ Bucket {bucket_name} does not exist or is not accessible")
                return False

            file_size = self.archive_path.stat().st_size

            def upload_progress(bytes_transferred):
                percent = (bytes_transferred / file_size) * 100
                print(f"  Upload progress: {percent:.1f}%", end='\r')

            s3_client.upload_file(
                str(self.archive_path),
                bucket_name,
                s3_key,
                Callback=upload_progress
            )

            print(f"\n✅ Successfully uploaded to s3://{bucket_name}/{s3_key}")
            return True

        except Exception as e:
            print(f"❌ Error uploading to S3: {e}")
            return False

    def cleanup(self, keep_archive: bool = True):
        """Clean up temporary files"""
        print("🧹 Cleaning up temporary files...")

        try:
            if self.model_dir.exists():
                shutil.rmtree(self.model_dir)
                print(f"  Removed {self.model_dir}")

            if not keep_archive and self.archive_path.exists():
                self.archive_path.unlink()
                print(f"  Removed {self.archive_path}")

            return True

        except Exception as e:
            print(f"⚠️  Warning during cleanup: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description="Download, prepare, and upload Qwen models for SageMaker deployment"
    )
    parser.add_argument(
        "--model-id",
        default="Qwen/Qwen2.5-VL-7B-Instruct",
        help="Hugging Face model ID (e.g., Qwen/Qwen2.5-VL-7B-Instruct, Qwen/Qwen2-7B-Instruct)"
    )
    parser.add_argument(
        "--model-name",
        help="Custom model name for file naming (auto-detected if not provided)"
    )
    parser.add_argument(
        "--bucket",
        required=True,
        help="S3 bucket name for model upload"
    )
    parser.add_argument(
        "--s3-key",
        help="S3 key (path) for model archive (default: <model-name>/model.tar.gz)"
    )
    parser.add_argument(
        "--region",
        default="ap-southeast-1",
        help="AWS region"
    )
    parser.add_argument(
        "--output-dir",
        default="./model_artifacts",
        help="Local directory for model artifacts"
    )
    parser.add_argument(
        "--skip-download",
        action="store_true",
        help="Skip download step (use existing model files)"
    )
    parser.add_argument(
        "--skip-upload",
        action="store_true",
        help="Skip upload step (only prepare model locally)"
    )
    parser.add_argument(
        "--keep-files",
        action="store_true",
        help="Keep temporary files after upload"
    )

    args = parser.parse_args()

    print("=" * 70)
    print("Qwen Model Preparation for SageMaker LMI Deployment")
    print("=" * 70)
    print()

    preparer = ModelPreparer(args.model_id, args.output_dir, args.model_name)

    print(f"Model ID: {args.model_id}")
    print(f"Model Name: {preparer.model_name}")
    print(f"Archive: {preparer.archive_path}")
    print()

    if not args.skip_download:
        if not preparer.download_model():
            sys.exit(1)
    else:
        print("⏭️  Skipping download (using existing files)")

    if not preparer.download_tiktoken_encodings():
        sys.exit(1)

    if not preparer.create_serving_properties():
        sys.exit(1)

    if not preparer.create_model_metadata():
        sys.exit(1)

    if not preparer.create_tarball():
        sys.exit(1)

    if not args.skip_upload:
        if not preparer.upload_to_s3(args.bucket, args.s3_key, args.region):
            sys.exit(1)
    else:
        print("⏭️  Skipping upload")
        print(f"📦 Model archive ready at: {preparer.archive_path}")

    if not args.keep_files:
        preparer.cleanup(keep_archive=args.skip_upload)

    print()
    print("=" * 70)
    print("✅ Model preparation completed successfully!")
    print("=" * 70)
    print()
    print("Next steps:")
    print("1. Run 'terraform apply' to create the SageMaker endpoint")
    print(f"2. Wait for endpoint to be InService (can take 10-15 minutes)")
    print("3. Use test_endpoint.py to test the deployed model")


if __name__ == "__main__":
    main()
