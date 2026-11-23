# Ansible monitoring configuration

Terraform creates the project network and the Prometheus, Grafana, Pi-hole, and Ansible control containers. Ansible runs inside the control container and uses its mounted Docker socket to create Node Exporter and provision Prometheus and Grafana. The control container must be attached to the project network for the health checks.

## Apply

After the team has deployed the Terraform stack, run these commands on its Docker host from an approved session. The Terraform configuration mounts the repository's `ansible/` directory at `/ansible` in the control container.

```sh
docker exec -u 0 ansible-node apk add --no-cache py3-requests
docker exec -w /ansible ansible-node ansible-galaxy collection install -r requirements.yml
docker exec -w /ansible ansible-node ansible-playbook --syntax-check playbook.yml
docker exec -w /ansible ansible-node ansible-playbook playbook.yml
docker exec -w /ansible ansible-node ansible-playbook playbook.yml
```

The first two commands install controller dependencies. Repeat them if Terraform replaces the control container. The second playbook run should report `changed=0` and `failed=0`. The defaults in `group_vars/controller.yml` match the current Terraform names and bridge DNS. Update those values if your deployment uses different names. There is one inventory target because the playbook executes from the Docker controller.

Prometheus and Grafana provisioning files are written inside Terraform's containers. Rerun the playbook after Terraform replaces either container to restore the files.

## Verify and simulate an outage

1. Open Prometheus on its configured host port and check **Status → Targets** for an UP target under `node_exporter`.
2. Open Grafana on its configured host port and select **Node Exporter Metrics**. Allow several scrapes for the rate panels to populate. Node Exporter collects Linux Docker host metrics with a read-only host-root mount and host PID namespace. Its network panel uses interfaces visible in the exporter's network namespace. This dashboard does not measure Pi-hole application health.
3. On the lab Docker host, run `docker stop confmanage-node-exporter`. Confirm `TargetDown` changes to firing on Prometheus's Alerts page within 60 seconds. Capture the initial, firing, and recovered states for the incident record.
4. Run `docker start confmanage-node-exporter` and confirm that the target returns to UP and the alert clears. Use the configured container name if you changed it.
