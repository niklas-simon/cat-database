echo '###############################################'
echo '#####          Install Packages           #####'
echo '###############################################'

apt-get install -y curl uidmap

echo '###############################################'
echo '#####           Install Docker            #####'
echo '###############################################'

wget -qO- https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sh

if [[ ! -z "${http_proxy}" || ! -z "${https_proxy}" ]]; then
    echo '###############################################'
    echo '#####           Configure Proxy           #####'
    echo '###############################################'

    wget https://raw.githubusercontent.com/niklas-simon/cat-database/main/docker-config.json
    sed s,{httpProxy},$(echo $http_proxy),g docker-config.json > config-1.json
    sed s,{httpsProxy},$(echo $https_proxy),g config-1.json > config.json
    runuser -u $SUDO_USER -- mkdir -p $HOME/.docker
    runuser -u $SUDO_USER -- cp config.json $HOME/.docker/config.json
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

echo '###############################################'
echo '#####      Configure non-root Access      #####'
echo '###############################################'

wget -qO- https://raw.githubusercontent.com/docker/docker-install/master/rootless-install.sh | runuser -u $SUDO_USER -- sh