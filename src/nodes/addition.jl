export AdditionNode

"""
Description:

    out = in1 + in2

           in2
           |
     in1   v  out
    ----->[+]----->

    f(in1,in2,out) = δ(out - in1 - in2)

Interfaces:

    1 i[:in1], 2 i[:in2], 3 i[:out]

Construction:

    AdditionNode(id=:my_node)
"""
type AdditionNode <: Node
    id::Symbol
    interfaces::Array{Interface,1}
    i::Dict{Symbol,Interface}

    function AdditionNode(; id=generateNodeId(AdditionNode))
        self = new(id, Array(Interface, 3), Dict{Symbol,Interface}())
        addNode!(currentGraph(), self)

        for (iface_index, iface_handle) in enumerate([:in1, :in2, :out])
            self.i[iface_handle] = self.interfaces[iface_index] = Interface(self)
        end

        return self
    end
end

isDeterministic(::AdditionNode) = true


############################################
# GaussianDistribution methods
############################################

function sumProductRule!(   node::AdditionNode,
                            outbound_interface_index::Type{Val{3}},
                            outbound_dist::GaussianDistribution,
                            msg_in1::Message{GaussianDistribution},
                            msg_in2::Message{GaussianDistribution},
                            msg_out::Any)

    dist_in1 = ensureParameters!(msg_in1.payload, (:m, :V))
    dist_in2 = ensureParameters!(msg_in2.payload, (:m, :V))
    outbound_dist.m = dist_in1.m + dist_in2.m
    outbound_dist.V = dist_in1.V + dist_in2.V
    outbound_dist.W = NaN
    outbound_dist.xi = NaN

    return outbound_dist
end

function sumProductRule!(   node::AdditionNode,
                            outbound_interface_index::Type{Val{2}},
                            outbound_dist::GaussianDistribution,
                            msg_in1::Message{GaussianDistribution},
                            msg_in2::Any,
                            msg_out::Message{GaussianDistribution})

    backwardAdditionRule!(outbound_dist, msg_in1.payload, msg_out.payload)
    return outbound_dist
end

function sumProductRule!(   node::AdditionNode,
                            outbound_interface_index::Type{Val{1}},
                            outbound_dist::GaussianDistribution,
                            msg_in1::Any,
                            msg_in2::Message{GaussianDistribution},
                            msg_out::Message{GaussianDistribution})

    backwardAdditionRule!(outbound_dist, msg_in2.payload, msg_out.payload)
    return outbound_dist
end

function backwardAdditionRule!(dist_result::GaussianDistribution, dist_in::GaussianDistribution, dist_out::GaussianDistribution)
    ensureParameters!(dist_out, (:m, :V))
    ensureParameters!(dist_in, (:m, :V))
    dist_result.m = dist_out.m - dist_in.m
    dist_result.V = dist_out.V + dist_in.V
    dist_result.W = NaN
    dist_result.xi = NaN

    return dist_result
end


#############################################
# DeltaDistribution methods
#############################################

function sumProductRule!(node::AdditionNode,
                         outbound_interface_index::Type{Val{3}},
                         outbound_dist::DeltaDistribution{Float64},
                         msg_in1::Message{DeltaDistribution{Float64}},
                         msg_in2::Message{DeltaDistribution{Float64}},
                         msg_out::Any)

    outbound_dist.m = msg_in1.payload.m + msg_in2.payload.m
    return outbound_dist
end

function sumProductRule!(node::AdditionNode,
                         outbound_interface_index::Type{Val{2}},
                         outbound_dist::DeltaDistribution{Float64},
                         msg_in1::Message{DeltaDistribution{Float64}},
                         msg_in2::Any,
                         msg_out::Message{DeltaDistribution{Float64}})

    backwardAdditionRule!(outbound_dist, msg_in1.payload, msg_out.payload)
    return outbound_dist
end

function sumProductRule!(node::AdditionNode,
                         outbound_interface_index::Type{Val{1}},
                         outbound_dist::DeltaDistribution{Float64},
                         msg_in1::Any,
                         msg_in2::Message{DeltaDistribution{Float64}},
                         msg_out::Message{DeltaDistribution{Float64}})

    backwardAdditionRule!(outbound_dist, msg_in2.payload, msg_out.payload)
    return outbound_dist
end

function backwardAdditionRule!(dist_result::DeltaDistribution{Float64}, dist_in::DeltaDistribution{Float64}, dist_out::DeltaDistribution{Float64})
    dist_result.m = dist_out.m - dist_in.m
    return dist_result
end


############################################
# Gaussian-DeltaDistribution combination
############################################

sumProductRule!(node::AdditionNode,
                outbound_interface_index::Type{Val{3}},
                outbound_dist::GaussianDistribution,
                msg_in1::Message{DeltaDistribution{Float64}},
                msg_in2::Message{GaussianDistribution},
                msg_out::Any) = sumProductRule!(node, outbound_interface_index, outbound_dist, convert(Message{GaussianDistribution}, msg_in1), msg_in2, msg_out)

sumProductRule!(node::AdditionNode,
                outbound_interface_index::Type{Val{3}},
                outbound_dist::GaussianDistribution,
                msg_in1::Message{GaussianDistribution},
                msg_in2::Message{DeltaDistribution{Float64}},
                msg_out::Any) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, convert(Message{GaussianDistribution}, msg_in2), msg_out)

sumProductRule!(node::AdditionNode,
                outbound_interface_index::Type{Val{1}},
                outbound_dist::GaussianDistribution,
                msg_in1::Any,
                msg_in2::Message{DeltaDistribution{Float64}},
                msg_out::Message{GaussianDistribution}) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, convert(Message{GaussianDistribution}, msg_in2), msg_out)

sumProductRule!(node::AdditionNode,
                outbound_interface_index::Type{Val{1}},
                outbound_dist::GaussianDistribution,
                msg_in1::Any,
                msg_in2::Message{GaussianDistribution},
                msg_out::Message{DeltaDistribution{Float64}}) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, msg_in2, convert(Message{GaussianDistribution}, msg_out))

sumProductRule!(node::AdditionNode,
                outbound_interface_index::Type{Val{2}},
                outbound_dist::GaussianDistribution,
                msg_in1::Message{DeltaDistribution{Float64}},
                msg_in2::Any,
                msg_out::Message{GaussianDistribution}) = sumProductRule!(node, outbound_interface_index, outbound_dist, convert(Message{GaussianDistribution}, msg_in1), msg_in2, msg_out)

sumProductRule!(node::AdditionNode,
                outbound_interface_index::Type{Val{2}},
                outbound_dist::GaussianDistribution,
                msg_in1::Message{GaussianDistribution},
                msg_in2::Any,
                msg_out::Message{DeltaDistribution{Float64}}) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, msg_in2, convert(Message{GaussianDistribution}, msg_out))


############################################
# MvGaussianDistribution methods
############################################

function sumProductRule!{T<:MvGaussianDistribution}(node::AdditionNode,
                                                    outbound_interface_index::Type{Val{3}},
                                                    outbound_dist::T,
                                                    msg_in1::Message{T},
                                                    msg_in2::Message{T},
                                                    msg_out::Any)

    forwardAdditionRule!(outbound_dist, msg_in1.payload, msg_in2.payload)
    return outbound_dist
end

function sumProductRule!{T<:MvGaussianDistribution}(node::AdditionNode,
                                                    outbound_interface_index::Type{Val{2}},
                                                    outbound_dist::T,
                                                    msg_in1::Message{T},
                                                    msg_in2::Any,
                                                    msg_out::Message{T})

    backwardAdditionRule!(outbound_dist, msg_in1.payload, msg_out.payload)
    return outbound_dist
end

function sumProductRule!{T<:MvGaussianDistribution}(node::AdditionNode,
                                                    outbound_interface_index::Type{Val{1}},
                                                    outbound_dist::T,
                                                    msg_in1::Any,
                                                    msg_in2::Message{T},
                                                    msg_out::Message{T})

    backwardAdditionRule!(outbound_dist, msg_in2.payload, msg_out.payload)
    return outbound_dist
end

function forwardAdditionRule!(dist_result::MvGaussianDistribution, dist_1::MvGaussianDistribution, dist_2::MvGaussianDistribution)
    # Calculations for a gaussian message type; Korl (2005), table 4.1
    if isValid(dist_1.m) && isValid(dist_1.V) && isValid(dist_2.m) && isValid(dist_2.V)
        dist_result.m = forwardAdditionMRule(dist_1.m, dist_2.m)
        dist_result.V = forwardAdditionVRule(dist_1.V, dist_2.V)
        invalidate!(dist_result.W)
        invalidate!(dist_result.xi)
    elseif isValid(dist_1.m) && isValid(dist_1.W) && isValid(dist_2.m) && isValid(dist_2.W)
        dist_result.m = forwardAdditionMRule(dist_1.m, dist_2.m)
        invalidate!(dist_result.V)
        dist_result.W = forwardAdditionWRule(dist_1.W, dist_2.W)
        invalidate!(dist_result.xi)
    elseif isValid(dist_1.xi) && isValid(dist_1.V) && isValid(dist_2.xi) && isValid(dist_2.V)
        invalidate!(dist_result.m)
        dist_result.V = forwardAdditionVRule(dist_1.V, dist_2.V)
        invalidate!(dist_result.W)
        dist_result.xi= forwardAdditionXiRule(dist_1.V, dist_1.xi, dist_2.V, dist_2.xi)
    else
        # Last resort: calculate (m,V) parametrization for both inbound messages
        ensureParameters!(dist_1, (:m, :V))
        ensureParameters!(dist_2, (:m, :V))
        dist_result.m = forwardAdditionMRule(dist_1.m, dist_2.m)
        dist_result.V = forwardAdditionVRule(dist_1.V, dist_2.V)
        invalidate!(dist_result.W)
        invalidate!(dist_result.xi)
    end

    return dist_result
end

function backwardAdditionRule!(dist_result::MvGaussianDistribution, dist_in::MvGaussianDistribution, dist_out::MvGaussianDistribution)
    # Calculations for a gaussian message type; Korl (2005), table 4.1
    if isValid(dist_in.m) && isValid(dist_in.V) && isValid(dist_out.m) && isValid(dist_out.V)
        dist_result.m = backwardAdditionMRule(dist_in.m, dist_out.m)
        dist_result.V = backwardAdditionVRule(dist_in.V, dist_out.V)
        invalidate!(dist_result.W)
        invalidate!(dist_result.xi)
    elseif isValid(dist_in.m) && isValid(dist_in.W) && isValid(dist_out.m) && isValid(dist_out.W)
        dist_result.m = backwardAdditionMRule(dist_in.m, dist_out.m)
        invalidate!(dist_result.V)
        dist_result.W = backwardAdditionWRule(dist_in.W, dist_out.W)
        invalidate!(dist_result.xi)
    elseif isValid(dist_in.xi) && isValid(dist_in.V) && isValid(dist_out.xi) && isValid(dist_out.V)
        invalidate!(dist_result.m)
        dist_result.V = backwardAdditionVRule(dist_in.V, dist_out.V)
        invalidate!(dist_result.W)
        dist_result.xi = backwardAdditionXiRule(dist_in.V, dist_in.xi, dist_out.V, dist_out.xi)
    else
        # Last resort: calculate (m,V) parametrization for both inbound messages
        ensureParameters!(dist_in, (:m, :V))
        ensureParameters!(dist_out, (:m, :V))
        dist_result.m = backwardAdditionMRule(dist_in.m, dist_out.m)
        dist_result.V = backwardAdditionVRule(dist_in.V, dist_out.V)
        invalidate!(dist_result.W)
        invalidate!(dist_result.xi)
    end

    return dist_result
end

# Rule set for forward propagation, from: Korl (2005), "A Factor graph approach to signal modelling, system identification and filtering", Table 4.1
forwardAdditionMRule{T<:Number}(m_x::Array{T, 1}, m_y::Array{T, 1}) = m_x + m_y
forwardAdditionVRule{T<:Number}(V_x::Array{T, 2}, V_y::Array{T, 2}) = V_x + V_y
forwardAdditionWRule{T<:Number}(W_x::Array{T, 2}, W_y::Array{T, 2}) = W_x * pinv(W_x + W_y) * W_y
forwardAdditionXiRule{T<:Number}(V_x::Array{T, 2}, xi_x::Array{T, 1}, V_y::Array{T, 2}, xi_y::Array{T, 1}) = pinv(V_x + V_y) * (V_x*xi_x + V_y*xi_y)

# Rule set for backward propagation, from: Korl (2005), "A Factor graph approach to signal modelling, system identification and filtering", Table 4.1
# The backward propagation merely negates the mean of the present input message (edge X) and uses the same rules to determine the missing input (edge Y)
# For the sake of clarity there is some redundancy between forward and backward rules.
backwardAdditionMRule{T<:Number}(m_x::Array{T, 1}, m_z::Array{T, 1}) = m_z - m_x
backwardAdditionVRule{T<:Number}(V_x::Array{T, 2}, V_z::Array{T, 2}) = V_x + V_z
backwardAdditionWRule{T<:Number}(W_x::Array{T, 2}, W_z::Array{T, 2}) = W_x * pinv(W_x + W_z) * W_z
backwardAdditionXiRule{T<:Number}(V_x::Array{T, 2}, xi_x::Array{T, 1}, V_z::Array{T, 2}, xi_z::Array{T, 1}) = pinv(V_x + V_z) * (V_z*xi_z - V_x*xi_x)


#############################################
# MvDeltaDistribution methods
#############################################

function sumProductRule!{T<:MvDeltaDistribution{Float64}}(  node::AdditionNode,
                                                            outbound_interface_index::Type{Val{3}},
                                                            outbound_dist::T,
                                                            msg_in1::Message{T},
                                                            msg_in2::Message{T},
                                                            msg_out::Any)

    outbound_dist.m = msg_in1.payload.m + msg_in2.payload.m
    return outbound_dist
end

function sumProductRule!{T<:MvDeltaDistribution{Float64}}(  node::AdditionNode,
                                                            outbound_interface_index::Type{Val{2}},
                                                            outbound_dist::T,
                                                            msg_in1::Message{T},
                                                            msg_in2::Any,
                                                            msg_out::Message{T})

    backwardAdditionRule!(outbound_dist, msg_in1.payload, msg_out.payload)
    return outbound_dist
end

function sumProductRule!{T<:MvDeltaDistribution{Float64}}(  node::AdditionNode,
                                                            outbound_interface_index::Type{Val{1}},
                                                            outbound_dist::T,
                                                            msg_in1::Any,
                                                            msg_in2::Message{T},
                                                            msg_out::Message{T})

    backwardAdditionRule!(outbound_dist, msg_in2.payload, msg_out.payload)
    return outbound_dist
end

function backwardAdditionRule!(dist_result::MvDeltaDistribution{Float64}, dist_in::MvDeltaDistribution{Float64}, dist_out::MvDeltaDistribution{Float64})
    dist_result.m = dist_out.m - dist_in.m
    return dist_result
end


############################################
# Gaussian-MvDeltaDistribution combination
############################################

sumProductRule!{TD<:MvDeltaDistribution{Float64}, TG<:MvGaussianDistribution}(
    node::AdditionNode,
    outbound_interface_index::Type{Val{3}},
    outbound_dist::TG,
    msg_in1::Message{TD},
    msg_in2::Message{TG},
    msg_out::Any) = sumProductRule!(node, outbound_interface_index, outbound_dist, convert(Message{MvGaussianDistribution}, msg_in1), msg_in2, msg_out)

sumProductRule!{TD<:MvDeltaDistribution{Float64}, TG<:MvGaussianDistribution}(
    node::AdditionNode,
    outbound_interface_index::Type{Val{3}},
    outbound_dist::TG,
    msg_in1::Message{TG},
    msg_in2::Message{TD},
    msg_out::Any) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, convert(Message{MvGaussianDistribution}, msg_in2), msg_out)

sumProductRule!{TD<:MvDeltaDistribution{Float64}, TG<:MvGaussianDistribution}(
    node::AdditionNode,
    outbound_interface_index::Type{Val{1}},
    outbound_dist::TG,
    msg_in1::Any,
    msg_in2::Message{TD},
    msg_out::Message{TG}) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, convert(Message{MvGaussianDistribution}, msg_in2), msg_out)

sumProductRule!{TD<:MvDeltaDistribution{Float64}, TG<:MvGaussianDistribution}(
    node::AdditionNode,
    outbound_interface_index::Type{Val{1}},
    outbound_dist::TG,
    msg_in1::Any,
    msg_in2::Message{TG},
    msg_out::Message{TD}) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, msg_in2, convert(Message{MvGaussianDistribution}, msg_out))

sumProductRule!{TD<:MvDeltaDistribution{Float64}, TG<:MvGaussianDistribution}(
    node::AdditionNode,
    outbound_interface_index::Type{Val{2}},
    outbound_dist::TG,
    msg_in1::Message{TD},
    msg_in2::Any,
    msg_out::Message{TG}) = sumProductRule!(node, outbound_interface_index, outbound_dist, convert(Message{MvGaussianDistribution}, msg_in1), msg_in2, msg_out)

sumProductRule!{TD<:MvDeltaDistribution{Float64}, TG<:MvGaussianDistribution}(
    node::AdditionNode,
    outbound_interface_index::Type{Val{2}},
    outbound_dist::TG,
    msg_in1::Message{TG},
    msg_in2::Any,
    msg_out::Message{TD}) = sumProductRule!(node, outbound_interface_index, outbound_dist, msg_in1, msg_in2, convert(Message{MvGaussianDistribution}, msg_out))
