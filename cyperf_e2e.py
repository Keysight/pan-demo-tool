import subprocess
import json
import urllib3
import cyperf

class CyPerfUtils(object):
    WAP_CLIENT_ID = 'clt-wap'

    def __init__(self, controller, username="", password="", license_server=None, license_user="", license_password=""):
        self.controller = controller
        self.host = f'https://{controller}'
        self.username = username
        self.password = password
        self.license_server   = license_server
        self.license_user     = license_user
        self.license_password = license_password

        self.configuration            = cyperf.Configuration(host=self.host)
        self.configuration.verify_ssl = False
        self.api_client               = cyperf.ApiClient(self.configuration)
        self.added_license_servers    = []

        self.authorize()
        self.update_license_server()

        self.agents = {}
        agents_api  = cyperf.AgentsApi(self.api_client)
        agents      = agents_api.get_agents()
        for agent in agents:
            self.agents[agent.ip] = agent

    def __del__(self):
        self.remove_license_server()

    def _authorize(self):
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        auth_api   = cyperf.AuthorizationApi(self.api_client)
        grant_type = "password"
        try:
            response = auth_api.auth_realms_keysight_protocol_openid_connect_token_post(client_id=CyPerfUtils.WAP_CLIENT_ID,
                                                                                        grant_type=grant_type,
                                                                                        password=self.password,
                                                                                        username=self.username)
            return response.access_token
        except cyperf.ApiException as e:
            raise (e)

    def authorize(self):
        self.configuration.access_token = self._authorize()

    def update_license_server(self):
        if not self.license_server or self.license_server == self.controller:
            return
        license_api = cyperf.LicenseServersApi(self.api_client)
        try:
            response = license_api.get_license_servers()
            for lServerMetaData in response:
                if lServerMetaData.host_name == self.license_server:
                    if 'ESTABLISHED' == lServerMetaData.connection_status:
                        pprint(f'License server {self.license_server} is already configured')
                        return
                    license_api.delete_license_servers(str(lServerMetaData.id))
                    waitTime = 5 # seconds
                    print (f'Waiting for {waitTime} seconds for the license server deletion to finish.')
                    time.sleep(5) # How can I avoid this sleep????
                    break
                    
            lServer = cyperf.LicenseServerMetadata(host_name=self.license_server,
                                                   trust_new=True,
                                                   user=self.license_user,
                                                   password=self.license_password)
            print (f'Configuring new license server {self.license_server}')
            newServers = license_api.create_license_servers(license_server_metadata=[lServer])
            while newServers:
                for server in newServers:
                    s = license_api.get_license_servers_by_id(
                        str(server.id))
                    if 'IN_PROGRESS' != s.connection_status:
                        newServers.remove(server)
                        self.added_license_servers.append(server)
                        if 'ESTABLISHED' == s.connection_status:
                            print(f'Successfully added license server {s.host_name}')
                        else:
                            raise Exception(f'Could not connect to license server {s.host_name}')
                time.sleep(0.5)
        except cyperf.ApiException as e:
            raise (e)

    def remove_license_server(self):
        license_api = cyperf.LicenseServersApi(self.api_client)
        for server in self.added_license_servers:
            try:
                license_api.delete_license_servers(str(server.id))
            except cyperf.ApiException as e:
                pprint(f'{e}')

    def load_configuration_files(self, configuration_files=[]):
        config_api = cyperf.ConfigurationsApi(self.api_client)
        config_ops = []
        for config_file in configuration_files:
            config_ops.append (config_api.start_configs_import(config_file))

        configs = []
        for op in config_ops:
            try:
                results  = op.await_completion ()
                configs += [(elem['id'], elem['configUrl']) for elem in results]
            except cyperf.ApiException as e:
                raise (e)
        return configs

    def load_configuration_file(self, configuration_file):
        configs = self.load_configuration_files ([configuration_file])
        if configs:
            return configs[0]
        else:
            return None

    def remove_configurations(self, configurations_ids=[]):
        config_api = cyperf.ConfigurationsApi(self.api_client)
        for config_id in configurations_ids:
            config_api.delete_configs (config_id)

    def remove_configuration(self, configurations_id):
        self.remove_configurations([configurations_id])

    def create_session_by_config_name (self, configName):
        configsApiInstance  = cyperf.ConfigurationsApi(self.api_client)
        appMixConfigs       = configsApiInstance.get_configs(search_col='displayName', search_val='CyPerf AppMix')
        if not len(appMixConfigs):
            return None

        return self.create_session (appMixConfigs[0].config_url)

    def create_session (self, config_url):
        session_api        = cyperf.SessionsApi(self.api_client)
        session            = cyperf.Session()
        session.config_url = config_url
        sessions           = session_api.create_sessions([session])
        if len(sessions):
            return sessions[0]
        else:
            return None

    def delete_session (self, session):
        session_api = cyperf.SessionsApi(self.api_client)
        test        = session_api.get_test (session_id = session.id)
        if test.status != 'STOPPED':
            self.stop_test(session)
        session_api.delete_sessions(session.id)

    def assign_agents (self, session, agent_map, augment=False):
        # Assing agents to the indivual network segments based on the input provided
        for net_profile in session.config.config.network_profiles:
            for ip_net in net_profile.ip_network_segment:
                if ip_net.name in agent_map:
                    mapped_ips    = agent_map[ip_net.name]
                    agent_details = [cyperf.AgentAssignmentDetails(agent_id = self.agents[agent_ip].id, id = self.agents[agent_ip].id) for agent_ip in mapped_ips if agent_ip in self.agents] # why do we need to pass agent_id and id both????
                    if not ip_net.agent_assignments:
                        ip_net.agent_assignments = cyperf.AgentAssignments(ByID=[], ByTag=[])

                    if augment:
                        ip_net.agent_assignments.by_id.extend(agent_details)
                    else:
                        ip_net.agent_assignments.by_id = agent_details

                    ip_net.update()

    def stop_test (self, session):
        test_ops_api = cyperf.TestOperationsApi(self.api_client)
        test_stop_op = test_ops_api.start_stop_traffic(session_id = session.id)
        try:
            test_stop_op.await_completion()
        except cyperf.ApiException as e:
            raise (e)

class Deployer(object):
    def __init__(self):
        self.terraform_dir = './terraform'

    def _get_utils(self, terraform_output):
        if 'mdw_detail' in terraform_output:
            controller     = terraform_output['mdw_detail']['value']
        else:
            controller     = None
        if 'license_server' in terraform_output:
            license_server = terraform_output['license_server']['value']
        else:
            license_server = None

        if not controller:
            return None

    def terraform_deploy(self):
        # cp tfvars inside ./terraform
        subprocess.run(['cp', 'terraform.tfvars', f'{self.terraform_dir}'], check=True)

        # Initialize Terraform    
        subprocess.run(['terraform', f'-chdir={self.terraform_dir}',  'init'], check=True)

        # Apply Terraform configuration
        subprocess.run(['terraform', f'-chdir={self.terraform_dir}', 'apply', '-auto-approve'], check=True)

    def collect_terraform_output(self):
        # Capture the output in JSON format
        result = subprocess.run(['terraform', f'-chdir={self.terraform_dir}', 'output', '-json'], capture_output=True, text=True, check=True)
        
        # Parse the JSON output
        terraform_output = json.loads(result.stdout)

        return terraform_output

    def terraform_destroy(self):
        # Destroy Terraform configuration
        subprocess.run(['terraform', f'-chdir={self.terraform_dir}', 'destroy', '-auto-approve'], check=True)

        # Remove all temporary files
        subprocess.run(['rm', '-f',  f'{self.terraform_dir}/terraform.tfvars'], check=True)
        subprocess.run(['rm', '-f',  f'{self.terraform_dir}/terraform.tfstate'], check=True)
        subprocess.run(['rm', '-f',  f'{self.terraform_dir}/terraform.tfstate.backup'], check=True)
        subprocess.run(['rm', '-f',  f'{self.terraform_dir}/.terraform.lock.hcl'], check=True)
        subprocess.run(['rm', '-rf', f'{self.terraform_dir}/.terraform/'], check=True)
        subprocess.run(['rm', '-f',  f'terraform.tfstate'], check=True)

    def deploy(self):
        self.terraform_deploy ()

        output = self.collect_terraform_output()
        utils  = self._get_utils(output)

    def destroy(self):
        output = self.collect_terraform_output()
        utils  = self._get_utils(output)

        self.terraform_destroy ()

def parse_cli_options():
    import argparse

    parser = argparse.ArgumentParser(description='Deploy a test topology for demonstrating palo-alto firewalls.')
    parser.add_argument('--deploy',  help='Deploy all components necessary for a palo-alto firewall demonstration', action='store_true')
    parser.add_argument('--destroy', help='Cleanup all components created for the last palto-alto firewall demonstration', action='store_true')
    args = parser.parse_args()

    return args

def main():
    args     = parse_cli_options()
    deployer = Deployer()

    print(f'{args.deploy=}, {args.destroy=}')
    if args.deploy:
        deployer.deploy()

    if args.destroy:
        deployer.destroy()
    '''
    # Run the function and store the output
    output = terraform_deploy()

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
    '''

if __name__ == "__main__":
    main()
