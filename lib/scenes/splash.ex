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

  # @parrot_hash  "UfHCVlANI2cFbwSpJey64FxjT-0"
  # @parrot_hash  "o85utvWj30E_3qWopRed9oOlauc"
  #@parrot_hash  "23ndsle1ASB5xHQVTHsiFcm3a3w"
  #@parrot_hash  "ABDvsbh7k4z3OYi9CjWlgf4iRiE"
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
      fill: {:image, {@parrot_hash, 1}}
    )
    |> rect(
      {@parrot_width, @parrot_height}, id: :not_parrot,
      fill: {:image, {@parrot_hash, 1}}
    )
    |> rect({5, 100}, fill: :white, id: :left)
    |> rect({5, 100}, fill: :white, id: :right)



    # calculate the transform that centers the parrot in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)
    move = {
      (vp_width / 2) - (@parrot_width / 2),
      (vp_height / 2) - (@parrot_height / 2)
    }

    # load the parrot texture into the cache
    Scenic.Cache.File.load( @parrot_path, :insecure)

    # move the parrot into the right location
    graph = Graph.modify( root_graph, :parrot, &update_opts(&1, translate: move) )
    |> push_graph()
    graph = Graph.modify( root_graph, :not_parrot, &update_opts(&1, translate: move) )
    |> push_graph()

    # move paddles into right locations
    graph = Graph.modify( root_graph, :left, &update_opts(&1, translate: {0, 10}) )
    |> push_graph()
    graph = Graph.modify( root_graph, :left, &update_opts(&1, translate: {400, 10}) )
    |> push_graph()

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@animate_ms, :animate)

    state = %{
      viewport: viewport,
      timer: timer,
      graph: graph,
      first_scene: first_scene,
      alpha: 255
    }

    push_graph(graph)

    {:ok, state}
  end

  # --------------------------------------------------------
  # A very simple animation. A timer runs, which increments a counter. The counter
  # Is applied as an alpha channel to the parrot png.
  # When it is fully saturated, transition to the first real scene
#  def handle_info( :animate,
#    %{timer: timer, alpha: a} = state
#  ) when a >= 256 do
#    :timer.cancel(timer)
#    Process.send_after(self(), :finish, @finish_delay_ms)
#    {:noreply, state}
#  end

#   def handle_info( :finish, state ) do
#     go_to_first_scene( state )
#     {:noreply, state }
#   end

  def handle_info( :animate, %{alpha: alpha, graph: graph} = state ) do
    graph = graph
    |> Graph.modify( :parrot, &update_opts(&1, fill: {:image, {@parrot_hash, alpha}}))
    |> push_graph()
    {:noreply, %{state | graph: graph, alpha: 255}}
    #{:noreply, state}
  end

  # --------------------------------------------------------
  # short cut to go right to the new scene on user input
#   def handle_input( {:cursor_button, {_,:press,_,_}}, _context, state ) do
#     IO.puts("in cursor handler")
#     # go_to_first_scene( state )
#     {:noreply, state}
#   end
   def handle_input( {:key, {"W", _, _}}, _context, state ) do
     IO.puts("W")
     # go_to_first_scene( state )
     {:noreply, state}
   end
   def handle_input( {:key, {"S", _, _}}, _context, state ) do
     IO.puts("S")
     # go_to_first_scene( state )
     {:noreply, state}
   end
   def handle_input( {:key, {"I", _, _}}, _context, state ) do
     IO.puts("I")
     # go_to_first_scene( state )
     {:noreply, state}
   end
   def handle_input( {:key, {"K", _, _}}, _context, state ) do
     IO.puts("K")
     # go_to_first_scene( state )
     {:noreply, state}
   end

   def handle_input( _input, _context, state ), do: {:noreply, state}


  # --------------------------------------------------------
#   defp go_to_first_scene( %{viewport: vp, first_scene: first_scene} ) do
#     ViewPort.set_root( vp, {first_scene, nil} )
#   end

end
