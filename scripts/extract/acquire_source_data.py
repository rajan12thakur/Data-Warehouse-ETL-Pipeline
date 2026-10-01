# This script is responsible for acquiring source data from the specified source directory and copying it to the target directory for further processing in the ETL pipeline.

# The source directory is specified in the .env file using the SOURCE_DATA_PATH variable. The script uses the pathlib library to handle file paths and the shutil library to copy files.


# import necessary libraries
from pathlib import Path
import shutil

from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Get/Read the source data path from the environment variable
source_root = os.getenv("SOURCE_DATA_PATH")    # returns a string or None

if not source_root:
    raise ValueError("SOURCE_DATA_PATH is not configured in the .env file.")


#convert the source_root string to a Path object
source_root = Path(source_root)

# Validate that the source root directory exists
if not source_root.is_dir():
    raise FileNotFoundError(
        f"Source directory does not exist: {source_root}"
    )

# Define the paths for the CRM and ERP source directories
# Locate CRM and ERP source directories
crm_source = source_root / "source_crm"
erp_source = source_root / "source_erp"


# Validate that the CRM and ERP source directories exist
# Validate CRM and ERP directories

if not crm_source.is_dir():
    raise FileNotFoundError(
        f"CRM source directory does not exist: {crm_source}"
    )

if not erp_source.is_dir():
    raise FileNotFoundError(
        f"ERP source directory does not exist: {erp_source}"
    )


# Now discover the CSV files
# Discover CSV files in CRM and ERP source directories

# Find files in this directory whose names end with .csv so use the glob() method of the Path object. The glob() method returns an iterator of Path objects matching the specified pattern. We convert this iterator to a list and sort it to ensure deterministic ordering.
# 
# We use:  sorted() so that the discovered list has deterministic ordering.

crm_files = sorted(crm_source.glob("*.csv"))
erp_files = sorted(erp_source.glob("*.csv"))



# Validate that files were actually discovered
if not crm_files:
    raise FileNotFoundError(
        f"No CSV files found in CRM source directory: {crm_source}"
    )

if not erp_files:
    raise FileNotFoundError(
        f"No CSV files found in ERP source directory: {erp_source}"
    )



# Define the raw destination
# Define the raw destination directory

project_root = Path(__file__).resolve().parents[2]

raw_root = project_root / "data" / "raw"

crm_destination = raw_root / "crm"
erp_destination = raw_root / "erp"

#Create the destination directories
crm_destination.mkdir(parents=True, exist_ok=True)
erp_destination.mkdir(parents=True, exist_ok=True)

# verify the destination paths
print(f"CRM destination: {crm_destination}")
print(f"ERP destination: {erp_destination}")


# Copy the CRM files

for source_file in crm_files:
    destination_file = crm_destination / source_file.name
    shutil.copy2(source_file, destination_file)



# Copy the ERP files
for source_file in erp_files:
    destination_file = erp_destination / source_file.name
    shutil.copy2(source_file, destination_file)


#Now the acquisition process handles both source systems generically
# print a message indicating that the acquisition process is complete
print("Source data acquisition complete. Files have been copied to the raw data directory.")     




