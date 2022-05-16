"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[109],{98217:function(e){e.exports=JSON.parse('{"functions":[{"name":"_tryDeactivatedCall","desc":"Calls the deactivated callback if the conditions for it are right","params":[],"returns":[{"desc":"","lua_type":"bool"}],"function_type":"method","private":true,"source":{"line":68,"path":"src/Signal/init.lua"}},{"name":"_tryActivatedCall","desc":"Calls the activated callback if the conditions for it are right","params":[],"returns":[{"desc":"","lua_type":"bool"}],"function_type":"method","private":true,"source":{"line":86,"path":"src/Signal/init.lua"}},{"name":"new","desc":"Constructs a new signal object.","params":[],"returns":[{"desc":"","lua_type":"Signal"}],"function_type":"static","source":{"line":106,"path":"src/Signal/init.lua"}},{"name":"is","desc":"Returns whether the passed argument is a signal","params":[{"name":"obj","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"boolean"}],"function_type":"static","source":{"line":146,"path":"src/Signal/init.lua"}},{"name":"enableQueueing","desc":"Enables argumenting queuing from fire calls when there are no connections and sets queueing to true","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":155,"path":"src/Signal/init.lua"}},{"name":"disableQueueing","desc":"Disables argumenting queuing from fire calls when there are no connections and sets queueing to false","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":167,"path":"src/Signal/init.lua"}},{"name":"enableDeferred","desc":"Enables deferred signaling and sets deferred to true","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":179,"path":"src/Signal/init.lua"}},{"name":"disableDeferred","desc":"Disables deferred signaling and sets deferred to false","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":190,"path":"src/Signal/init.lua"}},{"name":"setActivatedCallback","desc":"Sets the callback that is called when a connection is made from when there are no connections (an activated state enters).","params":[{"name":"fn","desc":"","lua_type":"function"}],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":202,"path":"src/Signal/init.lua"}},{"name":"setDeactivatedCallback","desc":"Sets the callback that is called when the last active connection is disconnected (a deactivated state enters).","params":[{"name":"fn","desc":"","lua_type":"function"}],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":212,"path":"src/Signal/init.lua"}},{"name":"fire","desc":"Fires the signal with the optional passed arguments. This method makes optimizations by recycling threads in cases where connections don\'t yield if deferred is false.","params":[{"name":"...","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":222,"path":"src/Signal/init.lua"}},{"name":"flush","desc":"Empties any queued arguments that may have been added when fire was called with no connections.","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":260,"path":"src/Signal/init.lua"}},{"name":"wait","desc":"Yields the current thread until the signal is fired and returns what was fired","params":[],"returns":[{"desc":"","lua_type":"any"}],"function_type":"method","yields":true,"source":{"line":272,"path":"src/Signal/init.lua"}},{"name":"promise","desc":"Wraps a wait call in a promise. This is preferred over calling wait directly.","params":[],"returns":[{"desc":"","lua_type":"Promise"}],"function_type":"method","source":{"line":281,"path":"src/Signal/init.lua"}},{"name":"connect","desc":"Connects a handler function to the signal so that it can be called when it\'s fired.","params":[{"name":"fn","desc":"","lua_type":"function"}],"returns":[{"desc":"","lua_type":"Connection"}],"function_type":"method","source":{"line":307,"path":"src/Signal/init.lua"}},{"name":"disconnectAll","desc":"Disconnects all connections","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":330,"path":"src/Signal/init.lua"}},{"name":"destroy","desc":"Disconnects all connections and sets the \\"destroyed\\" field to true","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":350,"path":"src/Signal/init.lua"}}],"properties":[],"types":[],"name":"Signal","desc":"Luau signal implementation","source":{"line":59,"path":"src/Signal/init.lua"}}')}}]);