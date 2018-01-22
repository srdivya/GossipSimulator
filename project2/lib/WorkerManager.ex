defmodule WorkerManager do
    use GenServer
    def start_link(numNodes, topology, algo) do
        numNodes = String.to_integer(numNodes)
        if(topology == "2D" || topology == "imp2D") do
            numNodes = round(:math.pow(Float.ceil(:math.sqrt(numNodes)),2))
            #IO.puts "numNodes = " <> Integer.to_string(numNodes)
        end
        {:ok, server_pid} = GenServer.start_link(__MODULE__,%{counter: 0, numNodes: numNodes, timer: nil, totalNodes: numNodes, algo: algo}, [name: :ServerName])
        #numNodes = String.to_integer(numNodes)
        actor_pids = spawn_actors(numNodes, numNodes, algo, [], topology)
        b = System.system_time(:millisecond)
        updateTimer(b)
        pid = Enum.random(actor_pids)
        #IO.inspect actor_pids
        #create Topology
        #adjList = getAdjList(actor_pids, topology)
        #createMap(actor_pids, topology, numNodes) 
        #IO.puts "in startlink after adjlist"   
        #IO.inspect adjListMap
        msg = "Hail Mary"
        
        cond do
            algo == "gossip" ->
                GossipWorker.sendMessage(:"#{pid}", msg, false)
            algo == "push-sum" ->
                PushSumWorker.startSend(:"#{pid}", pid)
        end
        :timer.sleep(100000000)
        #IO.puts "ENDDDD"
        {:ok, numNodes}
    end
    def init(state) do #numNodes, topology, algo) do
        #IO.puts "init"
        {:ok, state}
        #spawn_actors(numNodes, topology, algo)
    end
    def updateTimer(b) do
        GenServer.cast(:ServerName, {:updateTime, b})
    end
    def handle_cast({:updateTime, b}, state) do
        state = Map.put(state, :timer, b)
        {:noreply, state}
    end
    def spawn_actors(numNodes, noNodes, algo, actor_pids, topology) do
        #IO.puts "num = " <> numNodes <> " algo=" <> algo# <> "[]=" <> actor_pids
        cond do
            algo == "gossip" ->
                #callgossip workers
                if numNodes == 1 do
                    {:ok, pid} = GossipWorker.start_link(numNodes, noNodes, topology)
                    #IO.inspect pid
                    actor_pids = Enum.concat([pid], actor_pids)
                else
                    {:ok, pid} = GossipWorker.start_link(numNodes, noNodes, topology)
                    # IO.puts "spawn"
                    # IO.inspect pid
                    actor_pids = Enum.concat([pid], actor_pids)
                    spawn_actors(numNodes - 1, noNodes, algo, actor_pids, topology)
                end
            algo == "push-sum" ->
                #callpushsum
                if numNodes == 1 do
                    {:ok, pid} = PushSumWorker.start_link(numNodes, noNodes, topology)
                    #IO.inspect pid
                    actor_pids = Enum.concat([pid], actor_pids)
                else
                    {:ok, pid} = PushSumWorker.start_link(numNodes, noNodes, topology)
                    #IO.inspect pid
                    actor_pids = Enum.concat([pid], actor_pids)
                    spawn_actors(numNodes - 1, noNodes, algo, actor_pids, topology)
                end
        end
    end
    def dec_count do
        GenServer.cast(:ServerName, {:handle})
        #state = state - 1
        #{:ok, state}
    end
    def handle_cast({:handle}, state) do
        #IO.puts("handling")
        #IO.inspect state
        #state = String.to_integer(state)
        #if (state > 0) do
            #state = state - 1
        #end
        {:numNodes, numNodes} = Enum.at(state,2)
        {:counter, counter} = Enum.at(state,1)
        {:totalNodes, totalNodes} =Enum.at(state, 4)
        {:algo, algo} = Enum.at(state, 0)
        if ((totalNodes - numNodes)/totalNodes >0.5 && algo == "push-sum" && (counter == 0 || counter < 2)) do
            counter = 2
            IO.puts "Converged 50% of nodes"
            {:timer, time} =Enum.at(state, 3)
            timetaken = System.system_time(:millisecond) - time
            IO.inspect timetaken
            new_state = Map.put(state, :counter, counter)
        end
        if(counter == 0) do
            cond do
                numNodes > 0 ->
                    new_state = Map.put(state, :numNodes, numNodes - 1)
                                
                    #IO.puts "counter = #{counter}"
                    #IO.puts "numNodes = #{numNodes}"
                numNodes == 0 ->
                    IO.puts "Converged"
                    {:timer, time} =Enum.at(state, 3)
                    timetaken = System.system_time(:millisecond) - time
                    IO.inspect timetaken
                    new_state = Map.put(state, :counter, counter + 1)
            end   
        else
            new_state = state
        end
        {:noreply, new_state}
    end
end