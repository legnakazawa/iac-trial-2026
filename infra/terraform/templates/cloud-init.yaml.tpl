#cloud-config
package_update: true
packages:
  - docker.io
  - docker-compose-v2
  - git
  - jq

write_files:
  - path: /opt/workshop/.gitkeep
    content: ""
    owner: ${admin_username}:${admin_username}

runcmd:
  - usermod -aG docker ${admin_username}
  - systemctl enable docker
  - systemctl start docker
  - mkdir -p /opt/workshop/workshop
  - chown -R ${admin_username}:${admin_username} /opt/workshop
