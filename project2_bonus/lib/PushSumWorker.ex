defmodule PushSumWorker do
    use GenServer
    def start_link(nodeName, numNodes, topology) do
        {:ok, pid} = GenServer.start_link(__MODULE__, %{this_pid: nodeName, s: nodeName, w: 1, count: 0, numNodes: numNodes, topology: topology, adjList: nil, vector_ratio: nodeName, x: false}, [name: :"#{nodeName}"])
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
        #IO.puts "in setAdj"
        GenServer.cast(:"#{pid}",{:setList, pid, numNodes, topology} )
    end
    def handle_cast({:setList, pid, numNodes, topology}, state) do
        #IO.puts "in setadj handle"
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
    def startSend(pid, num) do
        sendMessage(:"#{pid}", 0, 1, false)
    end
    def sendMessage(pid, s, w, is_self) do
        GenServer.cast(:"#{pid}", {:sendMsg, pid, s, w, is_self})
    end
    def handle_cast({:sendMsg, pid, s_new, w_new, is_self}, state) do
        {:adjList, newAdjList} = Enum.at(state, 0)
        {:s, s} = Enum.at(state, 3)
        {:w, w} = Enum.at(state, 7)
        {:count, count} = Enum.at(state, 1)
        {:vector_ratio, ratio_list} = Enum.at(state, 6)
        #time = 0
        #rand = 1..100
        if (count < 3) do
            
            if(w==0.0) do            
                #:timer.sleep(10000)
                w = s/ ratio_list
                old = ratio_list
                #time = Enum.random(rand)
                #IO.puts "time = #{time}"
                #IO.puts "w = #{w} w_new = #{w_new}"
            else
                old = s/w
            end
            rand_pid = Enum.random(newAdjList)
            
            if(!is_self) do
                s = s + s_new
                w = w + w_new
            end 
            if(w==0.0 && is_self) do
            # IO.puts "wnew = #{w_new} isself = #{is_self}"
            #IO.puts "w= #{w} wnew = #{w_new} isself = #{is_self}"
                new = ratio_list
                #time = Enum.random(rand)
                #IO.puts "time = #{time}"
            else
                new = s/w
            end
            
            
            diff = new - old
            #if(count < 3) do
            s = s / 2
            w = w / 2
            #ratio_list = ratio_list ++ [old]
            state = Map.put(state, :s, s)
            state = Map.put(state, :w, w)
            if(Process.whereis(:"#{rand_pid}") != nil && Process.alive?(Process.whereis(:"#{rand_pid}"))) do
                #IO.puts "call someone else"
                GenServer.cast(:"#{pid}", {:GenCall})
                PushSumWorker.sendMessage(:"#{rand_pid}", s, w, false)
            else 
                rand_pid = Enum.random(newAdjList)
                if(Process.whereis(:"#{rand_pid}") != nil) do
                    #if (Process.alive?(Process.whereis(:"#{rand_pid}"))) do
                        PushSumWorker.sendMessage(:"#{rand_pid}", s, w, false)
                    #end
                end
            end
            if(abs(diff) < :math.pow(10, -10) && !is_self) do
                state = Map.put(state, :count, count + 1)
            else
                if count > 0 do
                    state = Map.put(state, :count, 0)
                end
            end
            #end
            #:timer.sleep(rand)
            PushSumWorker.sendMessage(:"#{pid}", s, w, true)
        else
            GenServer.cast(:"#{pid}", {:GenCall})
        end
        {:noreply, state, state}
    end
    def handle_cast({:GenCall}, state) do
        #IO.puts ":gencall handle"
        #IO.inspect state
        {:this_pid, pid} = Enum.at(state, 4)
        {:s, s} = Enum.at(state, 3)
        {:w, w} = Enum.at(state, 7)
        {:count, count} = Enum.at(state, 1)
        {:x, flag} = Enum.at(state, 8)
        #IO.puts "count"
        #IO.inspect count
        if(count == 3 && flag == false) do
            WorkerManager.dec_count
            IO.puts Integer.to_string(pid) <> " converged with #{s/w}" 
            state = Map.put(state, :x, true)
            #Process.exit(Process.whereis(:"#{pid}"), :kill)
        end
        # if(s/w > :math.pow(10, -10)  ) do
        #     if (count > 0) do
        #         count = 0
        #     end
        # else
        #     count = count + 1
        # end
        #new_state = Map.put(state, :count, count)
        {:noreply, state}
    end
end