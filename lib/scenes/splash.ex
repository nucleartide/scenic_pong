defmodule MyApp.Scene.Splash do
  @moduledoc """
  Sample splash scene.

  This scene demonstrate a very simple animation and transition to another scene.

  It also shows how to load a static texture and paint it into a rectangle.
  """

  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:rect, 3}, {:update_opts, 2}]

  def load(f) do
    file_path = :code.priv_dir(:my_app)
                |> Path.join(f)

    {:ok, data} = Scenic.Cache.File.read(file_path, :insecure)
    Scenic.Cache.Hash.compute(data, :sha)
  end

  @parrot_hash  "-5ZxQ0CtZmwu-2fX0N4na_lXLZQ"
  @parrot_path  :code.priv_dir(:my_app)
              |> Path.join( "/static/images/awesome_original2.png" )

  @parrot_width 50
  @parrot_height 50

  @animate_ms  30
  @finish_delay_ms 1000

  # --------------------------------------------------------
  def init( first_scene, opts ) do
    viewport = opts[:viewport]

    root_graph = Graph.build()
    |> rect(
      {@parrot_width, @parrot_height}, id: :parrot,
      fill: {:image, {@parrot_hash, 255}}
    )
    |> rect({5, 100}, fill: :white, id: :left)
    |> rect({5, 100}, fill: :white, id: :right)

    # calculate the transform that centers the parrot in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)
    move = {
      (vp_width / 2) - (@parrot_width / 2),
      (vp_height / 2) - (@parrot_height / 2)-100
    }

    # load the parrot texture into the cache
    Scenic.Cache.File.load( @parrot_path, :insecure)

    # move the parrot into the right location
    # move paddles into right locations
    graph = root_graph

    graph = Graph.modify(graph, :parrot, &update_opts(&1, translate: move) )
            |> push_graph()

    graph = Graph.modify(graph, :left, &update_opts(&1, translate: {20, 10}) )
    |> push_graph()

    graph = Graph.modify(graph, :right, &update_opts(&1, translate: {vp_width-20-10, 10}) )
    |> push_graph()

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@animate_ms, :animate)

    state = %{
      viewport: viewport,
      timer: timer,
      graph: graph,
      first_scene: first_scene,
      alpha: 255,
      vel: {2,2}
    }

    push_graph(graph)

    {:ok, state}
  end

  # --------------------------------------------------------
  # A very simple animation. A timer runs, which increments a counter. The counter
  # Is applied as an alpha channel to the parrot png.
  # When it is fully saturated, transition to the first real scene
  def handle_info( :animate, %{timer: timer, alpha: a} = state) do
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(state.viewport)
#    move = {
#      (vp_width / 2) - (@parrot_width / 2),
#      (vp_height / 2) - (@parrot_height / 2)
#    }

#    if x+@parrot_width > vp_width do
#      graph = Graph.modify(state.graph, :parrot, &update_opts(&1, translate: {x-2,y+2}) )
#      |> push_graph()
#    else

    {x,y} = Graph.get!(state.graph, :parrot).transforms.translate
    {vel_x, vel_y} = state.vel

    {right_x,right_y} = Graph.get!(state.graph, :right).transforms.translate
    {vel_x, vel_y} = state.vel

    if x+@parrot_width > right_x do
      if y+@parrot_height > vp_height do
        graph = Graph.modify(state.graph, :parrot, &update_opts(&1, translate: {x-2,y}))
        |> push_graph()
        {:noreply, %{ state | vel: {-vel_x, -vel_y}, graph: graph }}
      else
        graph = Graph.modify(state.graph, :parrot, &update_opts(&1, translate: {x-2,y-2}))
        |> push_graph()
        {:noreply, %{ state | vel: {-vel_x, vel_y}, graph: graph }}
      end
    else
      if y+@parrot_height > vp_height do
        graph = Graph.modify(state.graph, :parrot, &update_opts(&1, translate: {x,y-2}))
        |> push_graph()
        {:noreply, %{ state | vel: {vel_x, -vel_y}, graph: graph }}
      else
        graph = Graph.modify(state.graph, :parrot, &update_opts(&1, translate: {x+vel_x,y+vel_y}))
        |> push_graph()
        {:noreply, %{ state | graph: graph }}
      end
    end


    #:timer.cancel(timer)
    #Process.send_after(self(), :finish, @finish_delay_ms)
    #IO.puts("animate")
  end

#   def handle_info( :finish, state ) do
#     {:noreply, state }
#   end

   def handle_input( {:key, {"W", _, _}}, _context, state ) do
     IO.puts("W")
      {x,y} = Graph.get!(state.graph, :left).transforms.translate
       graph = Graph.modify( state.graph, :left, &update_opts(&1, translate: {x,y-12}) )
       |> push_graph()
     {:noreply, %{ state | graph: graph }}
   end
   def handle_input( {:key, {"S", _, _}}, _context, state ) do
     IO.puts("S")
      {x,y} = Graph.get!(state.graph, :left).transforms.translate
       graph = Graph.modify( state.graph, :left, &update_opts(&1, translate: {x,y+12}) )
       |> push_graph()
     {:noreply, %{ state | graph: graph }}
   end
   def handle_input( {:key, {"I", _, _}}, _context, state ) do
     IO.puts("I")
      {x,y} = Graph.get!(state.graph, :right).transforms.translate
       graph = Graph.modify( state.graph, :right, &update_opts(&1, translate: {x,y-12}) )
       |> push_graph()
     {:noreply, %{ state | graph: graph }}
   end
   def handle_input( {:key, {"K", _, _}}, _context, state ) do
     IO.puts("K")
      {x,y} = Graph.get!(state.graph, :right).transforms.translate
       graph = Graph.modify( state.graph, :right, &update_opts(&1, translate: {x,y+12}) )
       |> push_graph()
     {:noreply, %{ state | graph: graph }}
   end

   def handle_input( _input, _context, state ), do: {:noreply, state}
end
