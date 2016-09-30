{application,ssl_hello_world,
             [{description,"Cowboy Hello World example with SSL."},
              {vsn,"1"},
              {modules,[]},
              {registered,[ssl_hello_world_sup]},
              {applications,[cowboy,kernel,ssl,stdlib]},
              {mod,{ssl_hello_world_app,[]}},
              {env,[]}]}.
