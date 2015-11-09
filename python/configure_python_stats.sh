#!/bin/bash

# Remove links to default python 2.6 and replace with 2.7
sudo rm /usr/bin/python
sudo ln -s /usr/bin/python2.7 /usr/bin/python
sudo rm /usr/bin/pip
sudo ln -s /usr/bin/pip-2.7 /usr/bin/pip

# Install python packages on all nodes (necessary for pyspark)
sudo pip install boto
sudo pip install numpy
sudo pip install scipy
sudo pip install matplotlib
sudo pip install scikit-learn
sudo pip install pandas
sudo pip install happybase
