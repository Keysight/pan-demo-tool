import os
import time
import subprocess
import json
import urllib3
import cyperf
from datetime import datetime


class CyPerfUtils(object):
    class color:
       PURPLE = '\033[95m'
       CYAN = '\033[96m'
       DARKCYAN = '\033[36m'
       BLUE = '\033[94m'
       GREEN = '\033[92m'
       YELLOW = '\033[93m'
       RED = '\033[91m'
       BOLD = '\033[1m'
       UNDERLINE = '\033[4m'
       END = '\033[0m'

    def __init__(self, controller, username="", password="", license_server=None, license_user="", license_password="", eula_accept_interactive=True, alive_timeout=600):
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        self.controller               = controller
        self.host                     = f'https://{controller}'
        self.license_server           = license_server
        self.license_user             = license_user
        self.license_password         = license_password
        self.api_ready_wait_time      = 2

        self.configuration            = cyperf.Configuration(host=self.host,
                                                             username=username,
                                                             password=password,
                                                             eula_accept_interactive=eula_accept_interactive)
        self.configuration.verify_ssl = False
        self.api_client               = cyperf.ApiClient(self.configuration)
        self.added_license_servers    = []

        #TBD: this defaults to a timeout of 10m, should we take a custom timeout?
        self.api_client.wait_for_controller_up(alive_timeout)

        if self.license_server:
            self.update_license_server()

        self.agents_api = cyperf.AgentsApi(self.api_client)

    def _call_api(self, func):
        while 1:
            try:
                return func()
            except cyperf.exceptions.ServiceException as e:
                time.sleep(self.api_ready_wait_time)

    def _update_license_server(self):
        if not self.license_server or self.license_server == self.controller:
            return
        license_api = cyperf.LicenseServersApi(self.api_client)
        try:
            response = license_api.get_license_servers()
            for server in response:
                if server.host_name == self.license_server:
                    if 'ESTABLISHED' == server.connection_status:
                        self.added_license_servers.append(server)
                        print(f'License server {self.license_server} is already configured')
                        return
                    license_api.delete_license_servers(str(server.id))
                    waitTime = 5 # seconds
                    print (f'Waiting for {waitTime} seconds for the license server deletion to finish.')
                    time.sleep(waitTime) # How can I avoid this sleep????
                    break
                    
            lServer = cyperf.LicenseServerMetadata(host_name=self.license_server,
                                                   trust_new=True,
                                                   user=self.license_user,
                                                   password=self.license_password)
            print (f'Configuring new license server {self.license_server}')
            newServers = license_api.create_license_servers(license_server_metadata=[lServer])
            while newServers:
                for server in newServers:
                    s = license_api.get_license_servers_by_id(str(server.id))
                    if 'IN_PROGRESS' != s.connection_status:
                        newServers.remove(server)
                        self.added_license_servers.append(server)
                        if 'ESTABLISHED' == s.connection_status:
                            print(f'Successfully added license server {s.host_name}')
                        else:
                            raise Exception(f'Could not connect to license server {s.host_name}')
                time.sleep(1)
        except cyperf.ApiException as e:
            raise (e)

    def _remove_license_server(self):
        license_api = cyperf.LicenseServersApi(self.api_client)
        for server in self.added_license_servers:
            try:
                license_api.delete_license_servers(str(server.id))
            except cyperf.ApiException as e:
                print(f'{e}')

    def update_license_server(self):
        self._call_api(self._update_license_server)

    def remove_license_server(self):
        self._call_api(self._remove_license_server)

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

    def delete_all_configs (self):
        config_api = cyperf.ConfigurationsApi(self.api_client)
        configs    = config_api.get_configs()
        self.remove_configurations([config.id for config in configs if not config.readonly])

    def create_session_by_config_name (self, configName):
        config_api = cyperf.ConfigurationsApi(self.api_client)
        configs    = config_api.get_configs(search_col='displayName', search_val=configName)
        if not len(configs):
            return None

        return self.create_session (configs[0].config_url)

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

    def delete_sessions (self, sessions=[]):
        session_api = cyperf.SessionsApi(self.api_client)
        for session in sessions:
            test    = session_api.get_test (session_id = session.id)
            if test.status != 'STOPPED':
                self.stop_test(session)
            session_api.delete_sessions(session.id)

    def delete_all_sessions (self):
        session_api = cyperf.SessionsApi(self.api_client)
        result      = session_api.get_sessions()
        for session in result:
            self.delete_session(session)

    def set_gateway (self, session, network_name, gateway_ip):
        for net_profile in session.config.config.network_profiles:
            for ip_net in net_profile.ip_network_segment:
                if ip_net.name == network_name:
                    for ip_range in ip_net.ip_ranges:
                        ip_range.gw_start = gateway_ip
                        ip_range.gw_start = gateway_ip
                        ip_range.update()

    def __collect_agents(self, agent_map, timeout_seconds=300):
        init_time = datetime.now()
        elapsed_time = init_time - init_time
        collected_all_agents = True
        while elapsed_time.seconds < timeout_seconds:
            agents = self.agents_api.get_agents()
            collected_all_agents = True
            for ip in agent_map:
                matching_agents = [agent for agent in agents if agent.ip == ip]
                if len(matching_agents) > 0:
                    agent_map[ip] = matching_agents[0]
                else:
                    collected_all_agents = False
            if collected_all_agents:
                break
            print(f"Waiting for all required agents to be available... [{elapsed_time.seconds // 60}m{elapsed_time.seconds % 60}s passed]")
            time.sleep(10)
            elapsed_time = datetime.now() - init_time
        if not collected_all_agents:
            raise Exception(f"Some required agents were not connected to CyPerf Controller within {timeout_seconds}s")

    def assign_agents(self, session, agent_map, augment=False):
        # Assing agents to the indivual network segments based on the input provided
        for net_profile in session.config.config.network_profiles:
            for ip_net in net_profile.ip_network_segment:
                if ip_net.name in agent_map:
                    mapped_ips    = agent_map[ip_net.name]
                    agents_by_ip     = {ip: None for ip in mapped_ips}
                    self.__collect_agents(agents_by_ip)
                    # why do we need to pass agent_id and id both????
                    agent_details = [cyperf.AgentAssignmentDetails(agent_id=agent.id,
                                                                   id=agent.id)
                                     for agent in agents_by_ip.values()]
                    if not ip_net.agent_assignments:
                        ip_net.agent_assignments = cyperf.AgentAssignments(ByID=[], ByTag=[])
                    if augment:
                        ip_net.agent_assignments.by_id.extend(agent_details)
                    else:
                        ip_net.agent_assignments.by_id = agent_details
                    ip_net.agent_assignments.update()

    def stop_test(self, session):
        test_ops_api = cyperf.TestOperationsApi(self.api_client)
        test_stop_op = test_ops_api.start_stop_traffic(session_id = session.id)
        try:
            test_stop_op.await_completion()
        except cyperf.ApiException as e:
            raise (e)

    def patch_controller (self, key_file):
        # Copy all files from the 'simple-ui' folder to the controller
        local_folder = 'simple-ui'
        remote_folder = '/home/cyperf'
        ssh_user = 'cyperf'
        print("Uploading simple UI files...")
        total_files = len(os.listdir(local_folder))
        file_num = 1
        for file_name in os.listdir(local_folder):
            local_file = os.path.join(local_folder, file_name)
            if os.path.isfile(local_file):
                scp_command = [
                    "scp",
                    "-i", key_file,
                    "-o", "MACS=hmac-sha2-512",
                    "-o", "StrictHostKeyChecking=accept-new",
                    local_file,
                    f"{ssh_user}@{self.controller}:{remote_folder}"
                ]
                try:
                    print(f"Uploading file {file_num}/{total_files}...")
                    subprocess.run(scp_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    if file_name.endswith('.sh'):
                        chmod_command = [
                            "ssh",
                            "-i", key_file,
                            "-o", "MACS=hmac-sha2-512",
                            "-o", "StrictHostKeyChecking=accept-new",
                            f"{ssh_user}@{self.controller}",
                            f"chmod +x {remote_folder}/{file_name}"
                        ]
                        try:
                            subprocess.run(chmod_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                        except subprocess.CalledProcessError as chmod_error:
                            print(f"Failed to set +x for {local_file}. Error code: {chmod_error.returncode}")
                    file_num += 1
                except subprocess.CalledProcessError as scp_error:
                    print(f"Failed to copy {local_file}. Error code: {scp_error.returncode}")
                    # print(f"Error message:\n{scp_error.stderr.decode()}")
        print("Done uploading files, installing simple UI...")
        # Now call the script that patches the controller and switches to the simple UI
        patch_command = [
            "ssh",
            "-i", key_file,
            "-o", "MACS=hmac-sha2-512",
            f"{ssh_user}@{self.controller}",
            "./switch-to-simple-ui.sh"
        ]
        try:
            subprocess.run(patch_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError as switch_error:
            print(f"Failed to switch to simple UI. Error code: {switch_error.returncode}")
            # print(f"Error message:\n{switch_error.stderr.decode()}")


class Deployer(object):
    def __init__(self):
        self.terraform_dir             = './terraform'
        self.terraform_state_dir       = './terraform-state'

        self.controller_admin_user     = 'admin'
        self.controller_admin_password = 'CyPerf&Keysight#1'

        self.license_server_user       = self.controller_admin_user
        self.license_server_password   = self.controller_admin_password

        self.terraform_state_files     = ['.terraform',
                                          'terraform.tfvars',
                                          'terraform.tfstate',
                                          'terraform.tfstate.backup',
                                          '.terraform.lock.hcl']

    def _get_utils(self, terraform_output, eula_accept_interactive=True):
        if 'mdw_detail' in terraform_output:
            controller     = terraform_output['mdw_detail']['value']['public_ip']
        else:
            controller     = None
        if 'license_server' in terraform_output:
            license_server = terraform_output['license_server']['value']
        else:
            license_server = None

        if not controller:
            return None

        if license_server:
            return CyPerfUtils(controller,
                               username=self.controller_admin_user,
                               password=self.controller_admin_password,
                               license_server=license_server,
                               license_user=self.license_server_user,
                               license_password=self.license_server_password,
                               eula_accept_interactive=eula_accept_interactive)
        else:
            return CyPerfUtils(controller,
                               username=self.controller_admin_user,
                               password=self.controller_admin_password,
                               eula_accept_interactive=eula_accept_interactive)

    def terraform_initialize(self):
        # Populate expected terraform files from terraform state dir
        subprocess.run(['mkdir', '-p', self.terraform_state_dir])
        if not os.path.exists(f'{self.terraform_state_dir}/terraform.tfvars'):
            subprocess.run(['cp', 'terraform.tfvars', self.terraform_state_dir])
        for tf_state_file in self.terraform_state_files:
            if os.path.exists(f'{self.terraform_state_dir}/{tf_state_file}'):
                subprocess.run(['cp', '-r',
                                f'{self.terraform_state_dir}/{tf_state_file}',
                                f'{self.terraform_dir}/{tf_state_file}'],
                               check=False)
        # Initialize Terraform
        subprocess.run(['terraform', f'-chdir={self.terraform_dir}',  'init'],
                       check=True)

         
    def terraform_deploy(self):
        try:
            # Apply Terraform configuration
            subprocess.run(['terraform',
                            f'-chdir={self.terraform_dir}',
                            'apply',
                            '-auto-approve'], check=True)
        finally:
            # persist Terraform state to terraform state dir
            for tf_state_file in self.terraform_state_files:
                subprocess.run(['cp', '-r',
                                f'{self.terraform_dir}/{tf_state_file}',
                                f'{self.terraform_state_dir}/{tf_state_file}'],
                               check=False)

    def collect_terraform_output(self):
        # Capture the output in JSON format
        result = subprocess.run(['terraform',
                                 f'-chdir={self.terraform_dir}',
                                 'output',
                                 '-json'],
                                capture_output=True,
                                text=True,
                                check=True)
        # Parse the JSON output
        terraform_output = json.loads(result.stdout)

        return terraform_output

    def terraform_destroy(self):
        # Destroy Terraform configuration
        subprocess.run(['terraform', f'-chdir={self.terraform_dir}', 'destroy', '-auto-approve'], check=True)

        # Remove all temporary files
        for tf_state_file in self.terraform_state_files:
            subprocess.run(['rm', '-rf',
                            f'{self.terraform_dir}/{tf_state_file}'],
                           check=False)
            subprocess.run(['rm', '-rf',
                            f'{self.terraform_state_dir}/{tf_state_file}'],
                           check=False)

    def initialize(self, args):
        self.terraform_initialize()

    def _do_accept_eula_interactively(self):
        if 'CYPERF_EULA_ACCEPTED' in os.environ:
            if os.environ['CYPERF_EULA_ACCEPTED'] == 'true':
                return False

        return True

    def deploy(self, args):
        self.terraform_deploy()

        output = self.collect_terraform_output()
        utils  = self._get_utils(output, self._do_accept_eula_interactively())

        _, config_url = utils.load_configuration_file(args.config_file)
        session       = utils.create_session(config_url)

        if 'panfw_detail' in output:
            pan_fw_client_gw = output['panfw_detail']['value']['panfw_cli_private_ip']
            pan_fw_server_gw = output['panfw_detail']['value']['panfw_srv_private_ip']

        if 'private_key_pem' in output:

            private_key_pem = output['private_key_pem']['value']
            with open("genrated_private_key", "w") as file:
                print(private_key_pem, file=file)
            os.chmod("genrated_private_key", 0o600)
            utils.patch_controller("genrated_private_key")
            
        #aws_nw_fw_ip = 
        utils.set_gateway (session, 'PAN-VM-FW-Client', pan_fw_client_gw)
        utils.set_gateway (session, 'PAN-VM-FW-Server', pan_fw_server_gw)
        agents = {
            'PAN-VM-FW-Client': [agent['private_ip'] for agent in output['panfw_client_agent_detail']['value']],
            'AWS-NW-FW-Client': [agent['private_ip'] for agent in output['awsfw_client_agent_detail']['value']],
            'PAN-VM-FW-Server': [agent['private_ip'] for agent in output['panfw_server_agent_detail']['value']],
            'AWS-NW-FW-Server': [agent['private_ip'] for agent in output['awsfw_server_agent_detail']['value']]
        }
        utils.assign_agents (session, agents)

        url_string = utils.color.UNDERLINE + utils.color.BLUE + f'https://{utils.controller}' + utils.color.END
        print(f'\nCyPerf controller is at: {url_string}')

    def destroy(self, args):
        output = self.collect_terraform_output()
        try:
            utils = self._get_utils(output, eula_accept_interactive=False, alive_timeout=5)
            if utils:
                utils.delete_all_sessions()
                utils.delete_all_configs()
                utils.remove_license_server()
        except Exception:
            print("Failed while connecting to CyPerf Controller to remove licenses, ignoring...")
        self.terraform_destroy()

def parse_cli_options():
    import argparse

    parser = argparse.ArgumentParser(description='Deploy a test topology for demonstrating palo-alto firewalls.',
                                     epilog='''Please set the environment variable CYPERF_EULA_ACCEPTED to \'true\'
                                               if you accept the CyPerf EULA: https://keysight.com/find/sweula.
                                               Alternatively you can accept through an interactive prompt.''',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--deploy',  help='Deploy all components necessary for a palo-alto firewall demonstration', action='store_true')
    parser.add_argument('--destroy', help='Cleanup all components created for the last palto-alto firewall demonstration', action='store_true')
    parser.add_argument('--config-file', help='The name of the configuration file including path', default='./configurations/Palo-Alto-Firewall-Demo.zip')
    args = parser.parse_args()

    return args

def main():
    args     = parse_cli_options()
    deployer = Deployer()

    deployer.initialize(args)

    if args.deploy:
        deployer.deploy(args)

    if args.destroy:
        deployer.destroy(args)

if __name__ == "__main__":
    main()
