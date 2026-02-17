# Use official Tomcat image with JDK
FROM tomcat:9.0-jdk11

# Remove default ROOT app
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR from Maven build
COPY target/*.war /usr/local/tomcat/webapps/wwp.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
