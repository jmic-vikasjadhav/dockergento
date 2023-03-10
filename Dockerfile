# Base image
FROM php:8.1-fpm-alpine

# Install required packages
RUN apk add --no-cache nginx varnish

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

# Copy the Varnish configuration file
COPY varnish.vcl /etc/varnish/default.vcl

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Set the working directory
WORKDIR /var/www/html

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy the Magento 2 files
COPY . .

# Install Magento 2 dependencies
RUN composer install --no-dev

# Set the file permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Expose ports
EXPOSE 80 443

# Start Nginx and PHP-FPM
CMD ["sh", "-c", "service varnish start && service nginx start && php-fpm"]
