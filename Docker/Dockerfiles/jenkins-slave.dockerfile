FROM cmdv/tester:latest
RUN yum -y install openssh-server java-1.8.0-openjdk
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd
RUN useradd -m -d /home/jenkins -s /bin/sh jenkins &&\
    echo "jenkins:jenkins" | chpasswd
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN ssh-keygen -f /etc/ssh/ssh_host_key -N '' -t rsa1 && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
RUN ssh-keygen -A    
# Standard SSH port
EXPOSE 22

# RUN pip install git+https://github.com/indigo-dc/udocker
RUN yum -y install sudo \
  epel-release \
  ansible
RUN curl https://raw.githubusercontent.com/indigo-dc/udocker/master/ansible_install.yaml > ansible_install.yaml
RUN ansible-playbook ansible_install.yaml  

RUN useradd -m -s /bin/bash docker
#RUN usermod -aG sudo docker 
# Default command
CMD ["/usr/sbin/sshd", "-D"]

