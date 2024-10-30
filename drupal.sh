#!/bin/bash

# Update and upgrade the system
sudo apt update

# Install NGINX, MySQL, PHP, and necessary PHP extensions
sudo apt install -y nginx mysql-server php8.3-cli php8.3-fpm php8.3-mysql php8.3-xml php8.3-gd php8.3-curl php8.3-mbstring php8.3-zip php8.3-intl

# Install curl
sudo apt install curl -y

# Install Composer
cd /tmp
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer

# Create the /var/www directory if it doesn't exist and set up Drupal
sudo mkdir -p /var/www
cd /var/www
sudo composer create-project drupal/recommended-project drupal
sudo chown -R www-data:www-data /var/www/drupal
sudo chmod -R 755 /var/www/drupal

# Configure NGINX for Drupal
sudo tee /etc/nginx/sites-available/drupal > /dev/null <<EOL
server {
    listen 80;
    server_name localhost;

    root /var/www/drupal/web;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        try_files \$uri /index.php?\$query_string;
        expires max;
        log_not_found off;
    }

    location ~* \.(json|xml)$ {
        try_files \$uri /index.php?\$query_string;
        expires max;
        log_not_found off;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Enable the Drupal site and restart NGINX
sudo ln -s /etc/nginx/sites-available/drupal /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Configure MySQL for Drupal
sudo mysql -u root <<EOF
CREATE DATABASE drupal;
CREATE USER 'drupaluser'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON drupal.* TO 'drupaluser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "Drupal setup completed. Please access the site and finalize the installation."
