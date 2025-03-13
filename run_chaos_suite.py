#!/usr/bin/env python3
"""
Chaos Engineering Suite Runner

This script applies various chaos experiments and monitors their effects.
It's a more robust and flexible Python replacement for the original Bash script.
"""

import argparse
import os
import signal
import subprocess
import sys
import time
import yaml
from datetime import datetime
from typing import List, Dict, Any, Optional

# ANSI color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class ChaosExperiment:
    """Class representing a chaos experiment"""
    def __init__(self, file_path: str):
        self.file_path = file_path
        self.name = os.path.basename(file_path)
        self.data = self._load_yaml()
        
    def _load_yaml(self) -> Dict[str, Any]:
        """Load YAML file content"""
        try:
            with open(self.file_path, 'r') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"{Colors.RED}Error loading {self.file_path}: {str(e)}{Colors.ENDC}")
            return {}
    
    @property
    def experiment_name(self) -> str:
        """Get the experiment name from metadata"""
        try:
            return self.data['metadata']['name']
        except (KeyError, TypeError):
            return "unknown"
    
    @property
    def experiment_type(self) -> str:
        """Get the experiment type from kind"""
        try:
            return self.data['kind']
        except (KeyError, TypeError):
            return "unknown"
    
    @property
    def duration(self) -> str:
        """Get the experiment duration"""
        try:
            return self.data['spec']['duration']
        except (KeyError, TypeError):
            return "unknown"
    
    def __str__(self) -> str:
        return f"{self.experiment_type}: {self.experiment_name} (Duration: {self.duration})"

class ChaosRunner:
    """Main class for running chaos experiments"""
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.experiments = []
        self.monitor_process = None
        self.monitor_pid = None
        self.experiments_dir = "chaos-experiments"
        self.experiment_files = [
            "network-delay-chaos.yaml",
            "pod-failure-chaos.yaml", 
            "cpu-stress-chaos.yaml",
            "memory-stress-chaos.yaml",
            "io-chaos.yaml"
        ]
        self.workflow_file = "chaos-workflow.yaml"
        
    def load_experiments(self) -> None:
        """Load all experiment files"""
        for file_name in self.experiment_files:
            file_path = os.path.join(self.experiments_dir, file_name)
            if os.path.exists(file_path):
                self.experiments.append(ChaosExperiment(file_path))
            else:
                print(f"{Colors.YELLOW}Warning: {file_path} not found, skipping{Colors.ENDC}")
    
    def ensure_namespace(self) -> None:
        """Ensure the chaos-testing namespace exists"""
        print(f"{Colors.BLUE}Ensuring chaos-testing namespace exists...{Colors.ENDC}")
        cmd = "kubectl create namespace chaos-testing --dry-run=client -o yaml | kubectl apply -f -"
        self._run_command(cmd)
    
    def apply_experiment(self, experiment: ChaosExperiment) -> None:
        """Apply a single chaos experiment"""
        print(f"{Colors.BLUE}Applying {experiment}...{Colors.ENDC}")
        cmd = f"kubectl apply -f {experiment.file_path}"
        self._run_command(cmd)
    
    def apply_all_experiments(self) -> None:
        """Apply all individual chaos experiments"""
        for experiment in self.experiments:
            self.apply_experiment(experiment)
        print(f"{Colors.GREEN}All individual chaos experiments applied!{Colors.ENDC}")
    
    def start_monitoring(self) -> None:
        """Start monitoring pods during chaos"""
        print(f"{Colors.BLUE}Starting pod monitoring...{Colors.ENDC}")
        cmd = "kubectl get pods -l app=resilient-app -w"
        
        if self.args.output_dir:
            os.makedirs(self.args.output_dir, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_file = os.path.join(self.args.output_dir, f"pod_monitoring_{timestamp}.log")
            print(f"{Colors.BLUE}Logging pod monitoring to {log_file}{Colors.ENDC}")
            
            with open(log_file, 'w') as f:
                self.monitor_process = subprocess.Popen(
                    cmd.split(), 
                    stdout=f,
                    stderr=subprocess.STDOUT
                )
        else:
            self.monitor_process = subprocess.Popen(
                cmd.split(), 
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
        self.monitor_pid = self.monitor_process.pid
        print(f"{Colors.GREEN}Monitoring started (PID: {self.monitor_pid}){Colors.ENDC}")
    
    def apply_workflow(self) -> None:
        """Apply the chaos workflow"""
        workflow_path = os.path.join(self.experiments_dir, self.workflow_file)
        if os.path.exists(workflow_path):
            print(f"{Colors.BLUE}Applying chaos workflow...{Colors.ENDC}")
            cmd = f"kubectl apply -f {workflow_path}"
            result = self._run_command(cmd, check=False)
            if result.returncode != 0:
                print(f"{Colors.YELLOW}Warning: Workflow application failed. This might be due to version incompatibility.{Colors.ENDC}")
                print(f"{Colors.YELLOW}Continuing with individual experiments only.{Colors.ENDC}")
        else:
            print(f"{Colors.YELLOW}Warning: Workflow file {workflow_path} not found, skipping{Colors.ENDC}")
    
    def wait_for_completion(self, duration_seconds: int) -> None:
        """Wait for the chaos experiments to complete"""
        print(f"{Colors.BLUE}Waiting for chaos experiments to complete ({duration_seconds} seconds)...{Colors.ENDC}")
        
        # If verbose, show a countdown
        if self.args.verbose:
            for remaining in range(duration_seconds, 0, -1):
                sys.stdout.write(f"\rTime remaining: {remaining} seconds")
                sys.stdout.flush()
                time.sleep(1)
            sys.stdout.write("\rExperiments completed!                \n")
        else:
            time.sleep(duration_seconds)
            
        print(f"{Colors.GREEN}Chaos experiments completed!{Colors.ENDC}")
    
    def stop_monitoring(self) -> None:
        """Stop the pod monitoring process"""
        if self.monitor_process:
            print(f"{Colors.BLUE}Stopping monitoring process...{Colors.ENDC}")
            try:
                os.kill(self.monitor_pid, signal.SIGTERM)
                self.monitor_process.wait(timeout=5)
                print(f"{Colors.GREEN}Monitoring stopped{Colors.ENDC}")
            except (ProcessLookupError, subprocess.TimeoutExpired) as e:
                print(f"{Colors.YELLOW}Warning when stopping monitoring: {str(e)}{Colors.ENDC}")
                try:
                    os.kill(self.monitor_pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
    
    def check_experiment_status(self) -> None:
        """Check the status of all chaos experiments"""
        print(f"{Colors.BLUE}Checking status of chaos experiments...{Colors.ENDC}")
        cmd = "kubectl get podchaos,networkchaos,stresschaos,iochaos -n chaos-testing"
        self._run_command(cmd)
        
        print(f"{Colors.BLUE}Checking status of chaos workflow...{Colors.ENDC}")
        cmd = "kubectl get workflow -n chaos-testing"
        self._run_command(cmd, check=False)
    
    def cleanup_experiments(self) -> None:
        """Clean up all chaos experiments"""
        if not self.args.no_cleanup:
            if self.args.auto_cleanup or self._confirm_cleanup():
                print(f"{Colors.BLUE}Cleaning up chaos experiments...{Colors.ENDC}")
                for experiment in self.experiments:
                    cmd = f"kubectl delete -f {experiment.file_path}"
                    self._run_command(cmd, check=False)
                
                workflow_path = os.path.join(self.experiments_dir, self.workflow_file)
                if os.path.exists(workflow_path):
                    cmd = f"kubectl delete -f {workflow_path}"
                    self._run_command(cmd, check=False)
                
                print(f"{Colors.GREEN}Cleanup completed!{Colors.ENDC}")
    
    def _confirm_cleanup(self) -> bool:
        """Ask for confirmation before cleanup"""
        response = input(f"{Colors.YELLOW}Do you want to clean up the chaos experiments? (y/n): {Colors.ENDC}")
        return response.lower() in ('y', 'yes')
    
    def _run_command(self, cmd: str, check: bool = True) -> subprocess.CompletedProcess:
        """Run a shell command and return the result"""
        if self.args.verbose:
            print(f"{Colors.BOLD}Running: {cmd}{Colors.ENDC}")
        
        result = subprocess.run(
            cmd, 
            shell=True, 
            text=True,
            capture_output=not self.args.verbose
        )
        
        if check and result.returncode != 0:
            print(f"{Colors.RED}Command failed: {cmd}{Colors.ENDC}")
            if not self.args.verbose:
                print(f"{Colors.RED}Error: {result.stderr}{Colors.ENDC}")
            if not self.args.continue_on_error:
                sys.exit(1)
                
        return result
    
    def generate_report(self) -> None:
        """Generate a report of the chaos experiments"""
        if self.args.output_dir:
            print(f"{Colors.BLUE}Generating chaos experiment report...{Colors.ENDC}")
            os.makedirs(self.args.output_dir, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            report_file = os.path.join(self.args.output_dir, f"chaos_report_{timestamp}.md")
            
            with open(report_file, 'w') as f:
                f.write("# Chaos Engineering Experiment Report\n\n")
                f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                
                f.write("## Experiments Applied\n\n")
                for experiment in self.experiments:
                    f.write(f"- **{experiment.experiment_type}**: {experiment.experiment_name} (Duration: {experiment.duration})\n")
                
                f.write("\n## Pod Status\n\n")
                f.write("```\n")
                result = subprocess.run(
                    "kubectl get pods -l app=resilient-app", 
                    shell=True, 
                    text=True,
                    capture_output=True
                )
                f.write(result.stdout)
                f.write("```\n\n")
                
                f.write("## Experiment Status\n\n")
                f.write("```\n")
                result = subprocess.run(
                    "kubectl get podchaos,networkchaos,stresschaos,iochaos -n chaos-testing", 
                    shell=True, 
                    text=True,
                    capture_output=True
                )
                f.write(result.stdout)
                f.write("```\n\n")
                
                # Add metrics if Prometheus is available
                try:
                    result = subprocess.run(
                        "kubectl get svc -n monitoring prometheus -o name", 
                        shell=True, 
                        text=True,
                        capture_output=True
                    )
                    if result.returncode == 0:
                        f.write("## Metrics\n\n")
                        f.write("### CPU Usage\n\n")
                        f.write("Query: `sum(rate(container_cpu_usage_seconds_total{namespace=\"default\", pod=~\"resilient-app.*\"}[1m])) by (pod)`\n\n")
                        
                        f.write("### Memory Usage\n\n")
                        f.write("Query: `sum(container_memory_working_set_bytes{namespace=\"default\", pod=~\"resilient-app.*\"}) by (pod)`\n\n")
                        
                        f.write("### Pod Restarts\n\n")
                        f.write("Query: `kube_pod_container_status_restarts_total{namespace=\"default\", pod=~\"resilient-app.*\"}`\n\n")
                except Exception as e:
                    print(f"{Colors.YELLOW}Warning when checking Prometheus: {str(e)}{Colors.ENDC}")
            
            print(f"{Colors.GREEN}Report generated: {report_file}{Colors.ENDC}")
    
    def run(self) -> None:
        """Run the complete chaos suite"""
        print(f"{Colors.HEADER}===== Chaos Engineering Test Suite ====={Colors.ENDC}")
        print(f"{Colors.BLUE}Starting chaos experiments...{Colors.ENDC}")
        
        try:
            # Load experiments
            self.load_experiments()
            
            # Ensure namespace exists
            self.ensure_namespace()
            
            # Apply all experiments
            self.apply_all_experiments()
            
            # Wait for experiments to start
            time.sleep(5)
            
            # Start monitoring
            self.start_monitoring()
            
            # Apply workflow
            self.apply_workflow()
            
            # Wait for completion
            self.wait_for_completion(self.args.duration)
            
            # Stop monitoring
            self.stop_monitoring()
            
            # Check experiment status
            self.check_experiment_status()
            
            # Generate report
            if self.args.output_dir:
                self.generate_report()
            
            # Clean up experiments
            self.cleanup_experiments()
            
            print(f"{Colors.HEADER}===== Chaos Engineering Test Suite Completed ====={Colors.ENDC}")
            
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Interrupted by user. Cleaning up...{Colors.ENDC}")
            self.stop_monitoring()
            if not self.args.no_cleanup:
                self.cleanup_experiments()
            sys.exit(1)
        except Exception as e:
            print(f"{Colors.RED}Error: {str(e)}{Colors.ENDC}")
            self.stop_monitoring()
            if not self.args.no_cleanup:
                self.cleanup_experiments()
            sys.exit(1)

def parse_args() -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Run chaos engineering experiments on Kubernetes",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    parser.add_argument(
        "--duration", 
        type=int, 
        default=240,
        help="Duration in seconds to wait for experiments to complete"
    )
    
    parser.add_argument(
        "--output-dir", 
        type=str, 
        help="Directory to store logs and reports"
    )
    
    parser.add_argument(
        "--verbose", 
        action="store_true",
        help="Enable verbose output"
    )
    
    parser.add_argument(
        "--continue-on-error", 
        action="store_true",
        help="Continue execution even if a command fails"
    )
    
    parser.add_argument(
        "--no-cleanup", 
        action="store_true",
        help="Do not clean up experiments after completion"
    )
    
    parser.add_argument(
        "--auto-cleanup", 
        action="store_true",
        help="Automatically clean up without confirmation"
    )
    
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    runner = ChaosRunner(args)
    runner.run() 