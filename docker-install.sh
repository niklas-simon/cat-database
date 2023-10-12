echo '###############################################'
echo '#####          Install Packages           #####'
echo '###############################################'

sudo apt update
sudo apt install -y curl uidmap

echo '###############################################'
echo '#####           Install Docker            #####'
echo '###############################################'

wget -qO- https://raw.githubusercontent.com/docker/docker-install/master/install.sh | sudo sh

if [[ ! -z "${http_proxy}" || ! -z "${https_proxy}" ]]; then
    echo '###############################################'
    echo '#####           Configure Proxy           #####'
    echo '###############################################'

    wget https://raw.githubusercontent.com/niklas-simon/cat-database/main/docker-config.json
    sed s,{httpProxy},$(echo $http_proxy),g docker-config.json > config-1.json
    sed s,{httpsProxy},$(echo $https_proxy),g config-1.json > config.json
    mkdir -p $HOME/.docker
    cp config.json $HOME/.docker/config.json
    rm docker-config.json
    rm config-1.json
    rm config.json

    wget https://raw.githubusercontent.com/niklas-simon/cat-database/main/http-proxy.conf
    sed s,{httpProxy},$(echo $http_proxy),g http-proxy.conf > http-proxy-1.conf
    sed s,{httpsProxy},$(echo $https_proxy),g http-proxy-1.conf > http-proxy.conf
    sudo mkdir -p /etc/systemd/system/docker.service.d
    sudo cp http-proxy.conf /etc/systemd/system/docker.service.d/http-proxy.conf
    rm http-proxy.conf
    rm http-proxy-1.conf
    sudo systemctl daemon-reload
    sudo systemctl restart docker
fi

echo '###############################################'
echo '#####      Configure non-root Access      #####'
echo '###############################################'

wget -qO- https://raw.githubusercontent.com/docker/docker-install/master/rootless-install.sh | sh