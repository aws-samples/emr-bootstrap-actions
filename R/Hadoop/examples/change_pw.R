# Thanks to Louis Aslett (http://www.louisaslett.com/, aslett@stats.ox.ac.uk) 
# for providing this code example.

# NOTE: It is *highly* recommended that you immediately change the 
# default password for logging into RStudio, which you can do by logging 
# in via SSH (recommended) in the usual EC2 fashion.  Alternatively, 
# since this AMI was created to make RStudio Server accessible to those 
# who are less comfortable with Linux commands you can follow the 
# instructions below to change it without touching Linux (easy, but it 
# is technically less secure)

# You're still here, so for the easy method simply change the word 
# mypassword on the next line of R code to your chosen password.  
# Remember to make it at least 8 characters long or else Linux will 
# reject it.
pwd <- "mypassword"

# Then run this whole script.  It should report that the password was 
# updated successfully on the penultimate line of output.

system(paste('echo "rstudio\n',pwd,'\n',pwd,'\n" | passwd', sep=''))
rm(pwd)
