## Ruby Memcached Server
Ruby multiclient TCP sockets memcached server that runs by default on the **11211** port.

---

### Supported Commands:
- **set**: Sets a value to a key
- **add**: Sets a value to a non-existent key
- **replace**: Sets a value to a pre-existent key
- **append**: Adds a string after the original value
- **prepend**: Adds a string before the original value
- **cas**: Modifies a pre-existent value that haven't been previously modified
- **incr**: (Only for numeric values) increments a number to the current value number
- **decr**: (Only for numeric values) decrements a number to the current value number
- **get**: Gets a value from memcache
- **gets**: Gets a value with its Id from memcache
- **delete**: Deletes a registry by a given key
- **flush_all**: Deletes all elements stored in memcache
- **quit**: Closes current operation(Socket)

### How to run the Ruy Memcached server:
**Prerequisites:**
- Have [Ruby](https://www.ruby-lang.org/en/) Installed
- Have [RSpec](https://rspec.info) GEM installed
- Have Telnet Installed

**Steps to run the server:**
In order to keep it as simple as possible, you will only have to follow two steps to have your Ruby memcached server up and running.

**1.** Locate the `Server` folder and open it:
   ![Locate the ruby server folder](https://i.imgur.com/MZmhN2R.png)


**2.** Open a terminal or CMD inside the `Server` folder and run the command `ruby server.rb`: 
   ![exec the server using terminal or CMD](https://i.imgur.com/ZpY27oI.png)

And that's it, now you have a fully functional Memcached server running on the default port: **11211**

### How to issue sample commands using Telnet client:
Now that your Memcached server is up, you can use the Telnet client to issue commands this way:

**1.** Open a terminal or CMD and write `telnet localhost 11211`:
   ![run the Telnet client](https://i.imgur.com/A3zLlni.png)

**2.** Just start writing commands:
   ![run the Telnet client](https://i.imgur.com/BXnrTVE.png)

### How to execute the unit tests:

**1.** **With the server up and running**, in the project's root folder, open a terminal or CMD and type `rspec -P "**/*_spec.rb"` to run all unit tests associated to the server operations:
   ![exec the rspec command](https://i.imgur.com/waDZ02A.png)