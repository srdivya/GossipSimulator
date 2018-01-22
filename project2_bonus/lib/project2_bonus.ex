defmodule PROJECT2BONUS do
  #project2 numNodes topology algorithm
  def main(args) do
    #{_, [str], _} = OptionParser.parse(args)
    #IO.puts(Enum.at(args, 0))
    params = [Enum.at(args, 0),Enum.at(args, 1),Enum.at(args, 2), Enum.at(args, 3)]
    ProjectSupervisor.start_link(params)
  end
end
