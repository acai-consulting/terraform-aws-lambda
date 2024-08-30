import os
import json

def validate_and_load_json():
    # Define the expected file path
    file_path = os.path.join("sub-folder", "test.json")

    # Check if the file exists
    if not os.path.exists(file_path):
        print(f"Error: The file {file_path} does not exist in the current directory structure.")
        return None

    # Try to load the file as JSON
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
        print(f"Successfully loaded {file_path} as JSON.")
        return data
    except json.JSONDecodeError:
        print(f"Error: The file {file_path} is not valid JSON.")
        return None
    except Exception as e:
        print(f"An error occurred while reading the file: {str(e)}")
        return None

if __name__ == "__main__":
    # Run the validation and loading function
    json_data = validate_and_load_json()

    # If JSON was successfully loaded, print its contents
    if json_data:
        print("Contents of test.json:")
        print(json.dumps(json_data, indent=2))