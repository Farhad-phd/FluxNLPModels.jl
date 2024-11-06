using Zygote
"""
    f = obj(nlp, w)

    Evaluate the objective function f(w) of the non-linear programming (NLP) problem at the point w. 
    If the precision of w and the precision expected by the nlp are different, ensure that the type of nlp.w matches the precision required by w.
# Arguments
- `nlp::AbstractFluxNLPModel{T, S}`: the FluxNLPModel data struct;
- `w::AbstractVector{V}`: is the vector of weights/variables. The use of `V` allows for flexibility in specifying different precision types for weights and models.
# Output
- `f_w`: the new objective function.

"""
function NLPModels.obj(nlp::AbstractFluxNLPModel{T, S}, w::AbstractVector{V}) where {T, S, V}
  x, y = nlp.current_training_minibatch

  eltype(nlp.w) == V || update_type!(nlp, w) #Check if the type has changed 
  if eltype(x) != V
    x = V.(x)
  end

  set_vars!(nlp, w)
  increment!(nlp, :neval_obj)
  return nlp.loss_f(nlp.chain(x), y)
end

"""
    g = grad!(nlp, w, g)

Evaluate `∇f(w)`, the gradient of the objective function at `w` in place.

# Arguments
- `nlp::AbstractFluxNLPModel{T, S}`: the FluxNLPModel data struct;
- `w::AbstractVector{V}`: is the vector of weights/variables. The use of `V` allows for flexibility in specifying different precision types for weights and models.
- `g::AbstractVector{}`: the gradient vector.

# Output
- `g`: the gradient at point `w`.

"""
function NLPModels.grad!(
  nlp::AbstractFluxNLPModel{T, S},
  w::AbstractVector{V},
  g::AbstractVector{U},
) where {T, S, V, U}
  @lencheck nlp.meta.nvar w g
  x, y = nlp.current_training_minibatch

  if (eltype(nlp.w) != V)  # we check if the types are the same, 
    update_type!(nlp, w)
    g = V.(g)
    if eltype(x) != V
      x = V.(x)
    end
  end

  increment!(nlp, :neval_grad)
  g .= gradient(w_g -> local_loss(nlp, x, y, w_g), w)[1]
  return g
end

"""
    objgrad!(nlp, w, g)

Evaluate both `f(w)`, the objective function of `nlp` at `w`, and `∇f(w)`, the gradient of the objective function at `w` in place.

# Arguments
- `nlp::AbstractFluxNLPModel{T, S}`: the FluxNLPModel data struct;
- `w::AbstractVector{V}`: is the vector of weights/variables. The use of `V` allows for flexibility in specifying different precision types for weights and models.
- `g::AbstractVector{V}`: the gradient vector.

# Output
- `f_w`, `g`: the new objective function, and the gradient at point w.

"""
function NLPModels.objgrad!(
  nlp::AbstractFluxNLPModel{T, S},
  w::AbstractVector{V},
  g::AbstractVector{U},
) where {T, S, V, U}
  @lencheck nlp.meta.nvar w g
  x, y = nlp.current_training_minibatch

  if (eltype(nlp.w) != V)  # we check if the types are the same, 
    update_type!(nlp, w)
    g = V.(g)
    if eltype(x) != V
      x = V.(x)
    end
  end

  increment!(nlp, :neval_obj)
  increment!(nlp, :neval_grad)
  set_vars!(nlp, w)

  f_w = nlp.loss_f(nlp.chain(x), y)
  g .= gradient(w_g -> local_loss(nlp, x, y, w_g), w)[1]

  return f_w, g
end



"""
    h = hess!(nlp, w, h)

Evaluate `∇²f(w)`, the Hessian of the objective function at `w` in place.

# Arguments
- `nlp::AbstractFluxNLPModel{T, S}`: the FluxNLPModel data struct;
- `w::AbstractVector{V}`: is the vector of weights/variables. The use of `V` allows for flexibility in specifying different precision types for weights and models.
- `h::AbstractMatrix{V}`: the Hessian matrix.

# Output
- `h`: the Hessian at point `w`.

"""
function NLPModels.hess!(
  nlp::AbstractFluxNLPModel{T, S},
  w::AbstractVector{V},
  h::AbstractMatrix{U},
) where {T, S, V, U}
  @lencheck nlp.meta.nvar w h
  x, y = nlp.current_training_minibatch

  if (eltype(nlp.w) != V)  # we check if the types are the same
    update_type!(nlp, w)
    h = V.(h)
    if eltype(x) != V
      x = V.(x)
    end
  end

  increment!(nlp, :neval_hess)
  
  # Calculate the Hessian using Zygote
  loss_function = w_g -> local_loss(nlp, x, y, w_g)
  hessian_func = Zygote.hessian(loss_function, w)
  
  h .= hessian_func  # assuming hessian_func directly returns a matrix

  return h
end