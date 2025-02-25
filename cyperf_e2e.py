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

mdw_detail = output['mdw_detail']['value']
license_server = output['license_server']['value']
awsfw_client_agent_detail = output['awsfw_client_agent_detail']['value']
awsfw_server_agent_detail = output['awsfw_server_agent_detail']['value']
panfw_client_agent_detail = output['panfw_client_agent_detail']['value']
panfw_server_agent_detail = output['panfw_server_agent_detail']['value']


print("CyPerf Controller Detail:", mdw_detail)
print("CyPerf License Server Detail:", license_server)
print("awsfw CyPerf Client Agent Detail:", awsfw_client_agent_detail)
print("awsfw CyPerf Server Agent Detail:", awsfw_server_agent_detail)
print("panfw CyPerf Client Agent Detail:", panfw_client_agent_detail)
print("panfw CyPerf Server Agent Detail:", panfw_server_agent_detail)