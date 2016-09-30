{application,cowboy,
             [{description,"Small, fast, modular HTTP server."},
              {vsn,"0.9.0"},
              {modules,[]},
              {registered,[cowboy_clock,cowboy_sup]},
              {applications,[cowlib,crypto,kernel,ranch,stdlib]},
              {mod,{cowboy_app,[]}},
              {env,[]}]}.
