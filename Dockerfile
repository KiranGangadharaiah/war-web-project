# Use specific Tomcat version (avoid latest in production)
FROM tomcat:latest
MAINTER RAMA
# Remove default ROOT app (optional but recommended)
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file
COPY target/*.war /usr/local/tomcat/webapps/wwwp.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
