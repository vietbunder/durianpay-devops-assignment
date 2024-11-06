# Use the official Nginx image as the base
FROM nginx:latest

# Set the working directory to Nginx's default root
WORKDIR /usr/share/nginx/html

# Copy hello.txt from the repository to the Nginx root directory
COPY hello.txt /usr/share/nginx/html/index.html

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
