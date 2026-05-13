import zipfile
import os

zip_path = 'frontend/build_web.zip'
extract_path = 'frontend/build/web'

if not os.path.exists(extract_path):
    os.makedirs(extract_path)

with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    for member in zip_ref.infolist():
        # Replace backslashes with forward slashes for Linux compatibility
        filename = member.filename.replace('\\', '/')
        
        # Determine the target path
        target_path = os.path.join(extract_path, filename)
        
        # If it's a directory (ends with /), create it
        if filename.endswith('/'):
            if not os.path.exists(target_path):
                os.makedirs(target_path)
            continue
            
        # Ensure the parent directory exists
        parent_dir = os.path.dirname(target_path)
        if not os.path.exists(parent_dir):
            os.makedirs(parent_dir)
            
        # Extract the file
        with zip_ref.open(member) as source, open(target_path, 'wb') as target:
            target.write(source.read())

print(f"Successfully extracted {zip_path} to {extract_path} with path normalization.")
