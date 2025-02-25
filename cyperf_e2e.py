import subprocess
import json

def run_terraform():
    # cp tfvars inside ./terraform
    subprocess.run(["cp", "terraform.tfvars", "./terraform"], check=True)

    # Initialize Terraform    
    subprocess.run(["terraform", "-chdir=./terraform",  "init"], check=True)
    
    # Apply Terraform configuration
    subprocess.run(["terraform", "-chdir=./terraform", "apply", "-auto-approve"], check=True)
    
    # Capture the output in JSON format
    result = subprocess.run(["terraform", "-chdir=./terraform", "output", "-json"], capture_output=True, text=True, check=True)
    
    # Parse the JSON output
    terraform_output = json.loads(result.stdout)
    
    return terraform_output

# Run the function and store the output
output = run_terraform()

# Access specific details from the output
client_agent_detail = output['client_agent_detail']['value']
mdw_detail = output['mdw_detail']['value']
server_agent_detail = output['server_agent_detail']['value']

print("CyPerf Client Agent Detail:", client_agent_detail)
print("CyPerf Controller Detail:", mdw_detail)
print("CyPerf Server Agent Detail:", server_agent_detail)
