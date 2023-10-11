echo '###############################################'
echo '#####    Add Docker''s official GPG key    #####'
echo '###############################################'

apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo '###############################################'
echo '#####  Add the repository to Apt sources  #####'
echo '###############################################'

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

echo '###############################################'
echo '#####          Install Packages           #####'
echo '###############################################'

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if [[ ! -z "${http_proxy}" || ! -z "${https_proxy}" ]]; then
    echo '###############################################'
    echo '#####           Configure Proxy           #####'
    echo '###############################################'

    wget https://raw.githubusercontent.com/niklas-simon/cat-database/main/docker-config.json
    sed s,{httpProxy},$(echo $http_proxy),g docker-config.json > config-1.json
    sed s,{httpsProxy},$(echo $https_proxy),g config-1.json > config.json
    mkdir -p ~./.docker
    cp config.json ~./.docker/config.json
    rm docker-config.json
    rm config-1.json
    rm config.json

    wget https://raw.githubusercontent.com/niklas-simon/cat-database/main/http-proxy.conf
    sed s,{httpProxy},$(echo $http_proxy),g http-proxy.conf > http-proxy-1.conf
    sed s,{httpsProxy},$(echo $https_proxy),g http-proxy-1.conf > http-proxy.conf
    mkdir -p /etc/systemd/system/docker.service.d
    cp http-proxy.conf /etc/systemd/system/docker.service.d/http-proxy.conf
    rm http-proxy.conf
    rm http-proxy-1.conf
    systemctl daemon-reload
    systemctl restart docker
fi

echo "to get non-root access, run 'sh /usr/bin/dockerd-rootless-setuptool.sh install' as a non-root user"