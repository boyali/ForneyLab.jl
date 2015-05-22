export Interface
export clearMessage!, setMessage!, message, name

type Interface
    # An Interface belongs to a node and is used to send/receive messages.
    # An Interface has exactly one partner interface, with wich it forms an edge.
    # An Interface can be seen as a half-edge, that connects to a partner Interface to form a complete edge.
    # A message from node a to node b is stored at the Interface of node a that connects to an Interface of node b.
    node::Node
    edge::Union(AbstractEdge, Nothing)
    partner::Union(Interface, Nothing)
    message::Union(Message, Nothing)
end
Interface(node::Node) = Interface(node, nothing, nothing, nothing)

function show(io::IO, interface::Interface)
    iface_name = name(interface)
    (iface_name == "") || (iface_name = "($(iface_name))")
    println(io, "Interface $(findfirst(interface.node.interfaces, interface)) $(iface_name) of $(typeof(interface.node)) $(interface.node.name)")
end
function setMessage!(interface::Interface, message::Message)
    interface.message = deepcopy(message)
end
clearMessage!(interface::Interface) = (interface.message=nothing)
message(interface::Interface) = interface.message
function name(interface::Interface)
    # Return interface name
    for field in names(interface.node)
        if isdefined(interface.node, field) && is(getfield(interface.node, field), interface)
            return string(field)
        end
    end
    return ""
end

function ensureMessage!{T<:ProbabilityDistribution}(interface::Interface, payload_type::Type{T})
    # Ensure that interface carries a Message{payload_type}, used for in place updates
    if interface.message == nothing || typeof(interface.message.payload) != payload_type
        if payload_type <: DeltaDistribution
            interface.message = Message(payload_type())
        else
            interface.message = Message(vague(payload_type))
        end
    end

    return interface.message
end
