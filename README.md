# TFE4141_Project
This is a project for the course TFE4141–Design of Digital Systems I at NTNU.
The aim of the project is to create an hardware which optimise the encryption/decryption of messages using the RSA protocol.

# Important to note
The final design is not fully functional: only the few first messages are encoded and then some errors (due to handshaking?) occurs.

# Algorithm
We use a modular exponentiation algorithm wich is optimize with binary representation of numbers. The multiplication of numbers is made using the Blakley's algorithm.

# Using the design
To open and work on the design with Vivado, you need to run the file regenarate.tcl
