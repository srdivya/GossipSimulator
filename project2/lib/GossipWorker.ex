defmodule GossipWorker do
    use GenServer
    def start_link(nodeName, numNodes, topology) do
        {:ok, pid} = GenServer.start_link(__MODULE__, %{this_pid: nodeName, count: 10, numNodes: numNodes, topology: topology, adjList: nil, x: false}, [name: :"#{nodeName}"])
        #setPID(nodeName)
        setAdjList(nodeName, numNodes, topology)
        #IO.inspect(pid)
        {:ok, nodeName}# pid}
    end
    def init(state) do
        #IO.inspect state
        {:ok, state}
    end
    def setAdjList(pid, numNodes, topology) do
        GenServer.cast(:"#{pid}",{:setList, pid, numNodes, topology} )
    end
    def handle_cast({:setList, pid, numNodes, topology}, state) do
        range = 1..numNodes
        actor_pids = Enum.to_list(range)
        cond do
            topology == "full" ->
                #IO.puts "here"
                newAdjList = List.delete(actor_pids, pid)
                #IO.puts "newlist"
                #IO.inspect newAdjList
                #GossipWorker.setAdjList(:"#{pid}", newAdjList)
            topology == "line" ->
                newAdjList = []
                cond do
                    pid == 1 ->
                        newAdjList = [pid + 1]
                    pid == numNodes ->
                        newAdjList = [pid - 1]
                    newAdjList == [] ->
                        newAdjList = Enum.concat([pid - 1], newAdjList)
                        newAdjList = Enum.concat([pid + 1], newAdjList)
                        # pid - 1 | pid + 1
                end
                #IO.inspect newAdjList
            topology == "2D" ->
                newAdjList = []
                sqrt = round(:math.sqrt(numNodes))                
                top = pid - sqrt
                bottom = pid + sqrt
                left = pid - 1
                right = pid + 1 
                if(top > 0) do
                    newAdjList = Enum.concat([top], newAdjList)
                end
                if(bottom < numNodes) do
                    newAdjList = Enum.concat([bottom], newAdjList)
                end
                if (rem((pid - 1), sqrt) != 0) do
                    newAdjList = Enum.concat([left], newAdjList)
                end
                if (rem(pid, sqrt) != 0) do
                    newAdjList = Enum.concat([right], newAdjList)
                end
                # IO.puts "2D for " <> Integer.to_string(pid)
                # IO.inspect newAdjList
            topology == "imp2D" ->
                newAdjList = []
                sqrt = round(:math.sqrt(numNodes))                
                top = pid - sqrt
                bottom = pid + sqrt
                left = pid - 1
                right = pid + 1 
                if(top > 0) do
                    newAdjList = Enum.concat([top], newAdjList)
                end
                if(bottom < numNodes) do
                    newAdjList = Enum.concat([bottom], newAdjList)
                end
                if (rem((pid - 1), sqrt) != 0) do
                    newAdjList = Enum.concat([left], newAdjList)
                end
                if (rem(pid, sqrt) != 0) do
                    newAdjList = Enum.concat([right], newAdjList)
                end
                rest = actor_pids -- newAdjList
                rest = List.delete(rest, pid)
                # IO.puts "rest for " <>  Integer.to_string(pid)
                # IO.inspect rest
                newAdjList = Enum.concat([Enum.random(rest)], newAdjList)
                # IO.puts "imp for " <>  Integer.to_string(pid)
                # IO.inspect newAdjList
        end
        # IO.puts "in set b4 map put"
        # IO.inspect padjList
        new_state = Map.put(state, :adjList, newAdjList)
        # IO.puts "setlist"
        # IO.inspect new_state
        {:noreply, new_state}
    end
    def sendMessage(pid, msg, is_self) do
        #IO.puts "sendmsg"
        GenServer.cast(:"#{pid}", {:sendMsg, pid, msg, is_self})
    end
    def handle_cast({:sendMsg, pid, msg, is_self}, state) do
        #IO.puts "in sendmsg handle"
        #IO.inspect state
        {:adjList, newAdjList} = Enum.at(state, 0)
        {:count, count} = Enum.at(state, 1)
        rand_pid = Enum.random(newAdjList)
        #rand_count = GossipWorker.getCount(:"#{rand_pid}")
        #IO.puts "rand count = " <> Integer.to_string(rand_count)
        if(count >= 0) do
            if(!is_self) do
                if(count > 0) do
                    GenServer.cast(:"#{pid}", {:GenCall})
                    #adjList = Enum.concat(newAdjList, [pid]) #change this, 
                    GossipWorker.sendMessage(:"#{rand_pid}", msg, false)
                    GossipWorker.sendMessage(:"#{pid}", msg, true)
                else
                     GenServer.cast(:"#{pid}", {:GenCall})
                end
            else
                GossipWorker.sendMessage(:"#{rand_pid}", msg, false)
                GossipWorker.sendMessage(:"#{pid}", msg, true)
                #GenServer.cast(:"#{rand_pid}", {:GenCall})
            end
            #IO.inspect state
            #GossipWorker.sendMessage(:"#{pid}", msg)
        end
        #GossipWorker.sendMessage(:"#{pid}", msg, true)
        {:noreply, state}
    end
    def handle_cast({:GenCall}, state) do
        #IO.puts ":gencall handle"
        #IO.inspect state
        {:this_pid, pid} = Enum.at(state, 3)
        {:count, count} = Enum.at(state, 1)
        {:x, flag} = Enum.at(state, 5)
        #IO.puts "count"
        #IO.inspect count
        if(count == 0 && flag == false) do
            WorkerManager.dec_count
            new_state = Map.put(state, :x, true)
            #Process.exit(Process.whereis(:"#{pid}"), :kill)
        end
        if(count > 0) do
            new_state = Map.put(state, :count, count-1)
        else
            new_state = state
        end
        {:noreply, new_state}
    end
end