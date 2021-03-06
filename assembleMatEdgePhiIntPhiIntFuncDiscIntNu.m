% Assembles two matrices containing integrals over edges of products of two 
% basis functions from the interior of each element and a function in discrete
% representation with a component of the edge normal.

%===============================================================================
%> @file assembleMatEdgePhiIntPhiIntFuncDiscIntNu.m
%>
%> @brief Assembles two matrices containing integrals over edges of products of
%>        two basis functions from the interior of each element and a function
%>        in discrete representation with a component of the edge normal.
%===============================================================================
%>
%> @brief Assembles matrices
%>        @f$\mathsf{{R}}^m_\mathrm{D}, m\in\{1,2\}@f$ containing integrals over  
%>        edges of products of two basis functions and a function in discrete 
%>        representation from the interior of each element.
%>
%> The matrix @f$\mathsf{{R}}^m_\mathrm{D}\in\mathbb{R}^{KN\times KN}@f$
%> is block diagonal and defined as
%> @f[
%> [\mathsf{{R}}^m_\mathrm{D}]_{(k-1)N+i,(k-1)N+j} =
%>  \sum_{E_{kn} \in \partial T_k \cap \mathcal{E}_D}
%>  \nu_{kn}^m \sum_{l=1}^N D_{kl}(t) 
%>  \int_{E_kn} \varphi_{ki}\varphi_{kl}\varphi_{kj} \,,
%> @f]
%> with @f$\nu_{kn}@f$ the @f$m@f$-th component (@f$m\in\{1,2\}@f$) of the unit
%> normal and @f$D_{kl}(t)@f$ the coefficients of the discrete representation
%> of a function 
%> @f$ d_h(t, \mathbf{x}) = \sum_{l=1}^N D_{kl}(t) \varphi_{kl}(\mathbf{x}) @f$
%> on a triangle @f$T_k@f$.
%> All other entries are zero.
%> To allow for vectorization, the assembly is reformulated as
%> @f[
%> \mathsf{{R}}^m_\mathrm{D} = \sum_{n=1}^3 \sum_{l=1}^N
%>   \begin{bmatrix}
%>     \delta_{E_{1n}\in\mathcal{E}_\mathrm{D}} &   & \\
%>     & ~\ddots~ & \\
%>     &          & \delta_{E_{Kn}\in\mathcal{E}_\mathrm{D}}
%>   \end{bmatrix} \circ
%>   \begin{bmatrix}
%>     \nu^m_{1n} |E_{1n}| D_{1l}(t) & & \\
%>     & ~\ddots~ & \\
%>     &          & \nu^m_{Kn} |E_{Kn}| D_{Kl}(t)
%>   \end{bmatrix} \otimes [\hat{\mathsf{{R}}}^\mathrm{diag}]_{:,:,l,n}\;,
%> @f]
%> where @f$\delta_{E_{kn}\in\mathcal{E}_\mathrm{D}}@f$ denotes the Kronecker 
%> delta, @f$\circ@f$ denotes the Hadamard product, and @f$\otimes@f$ denotes
%> the Kronecker product.
%>
%> The entries of matrix 
%> @f$\hat{\mathsf{{R}}}^\mathrm{diag}\in\mathbb{R}^{N\times N\times N\times3}@f$
%> are given by
%> @f[
%> [\hat{\mathsf{{R}}}^\mathrm{diag}]_{i,j,l,n} =
%>   \int_0^1 \hat{\varphi}_i \circ \hat{\mathbf{\gamma}}_n(s) 
%>   \hat{\varphi}_l \circ \hat{\mathbf{\gamma}}_n(s) 
%>   \hat{\varphi}_j\circ \hat{\mathbf{\gamma}}_n(s) \mathrm{d}s \,,
%> @f]
%> where the mapping @f$\hat{\mathbf{\gamma}}_n@f$ is defined in 
%> <code>gammaMap()</code>.
%>
%> It is essentially the same as the diagonal part of
%> <code>assembleMatEdgePhiPhiFuncDiscNu()</code>.
%>
%> @param  g          The lists describing the geometric and topological 
%>                    properties of a triangulation (see 
%>                    <code>generateGridData()</code>) 
%>                    @f$[1 \times 1 \text{ struct}]@f$
%> @param  markE0Tbdr <code>logical</code> arrays that mark each triangles
%>                    (boundary) edges on which the matrix blocks should be
%>                    assembled @f$[K \times 3]@f$
%> @param refEdgePhiIntPhiIntPhiInt  Local matrix 
%>                    @f$\hat{\mathsf{{R}}}^\text{diag}@f$ as provided
%>                    by <code>integrateRefEdgePhiIntPhiIntPhiInt()</code>.
%>                    @f$[N \times N \times N \times 3]@f$
%> @param dataDisc    A representation of the discrete function 
%>                    @f$d_h(\mathbf(x))@f$, e.g., as computed by 
%>                    <code>projectFuncCont2DataDisc()</code>
%>                    @f$[K \times N]@f$
%> @param areaNuE0Tbdr (optional) argument to provide precomputed values
%>                    for the products of <code>markE0Tbdr</code>,
%>                    <code>g.areaE0T</code>, and <code>g.nuE0T</code>
%>                    @f$[3 \times 2 \text{ cell}]@f$
%> @retval ret        The assembled matrices @f$[2 \times 1 \text{ cell}]@f$
%>
%> This file is part of FESTUNG
%>
%> @copyright 2014-2015 Florian Frank, Balthasar Reuter, Vadym Aizinger
%> Modified by Hennes Hajduk, 2016-04-06
%> 
%> @par License
%> @parblock
%> This program is free software: you can redistribute it and/or modify
%> it under the terms of the GNU General Public License as published by
%> the Free Software Foundation, either version 3 of the License, or
%> (at your option) any later version.
%>
%> This program is distributed in the hope that it will be useful,
%> but WITHOUT ANY WARRANTY; without even the implied warranty of
%> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%> GNU General Public License for more details.
%>
%> You should have received a copy of the GNU General Public License
%> along with this program.  If not, see <http://www.gnu.org/licenses/>.
%> @endparblock
%
function ret = assembleMatEdgePhiIntPhiIntFuncDiscIntNu(g, markE0Tbdr, refEdgePhiIntPhiIntPhiInt, dataDisc, areaNuE0Tbdr)
% Extract dimensions
[K, N] = size(dataDisc);  

% Check function arguments that are directly used
validateattributes(dataDisc, {'numeric'}, {'size', [g.numT N]}, mfilename, 'dataDisc');
validateattributes(markE0Tbdr, {'logical'}, {'size', [K 3]}, mfilename, 'markE0Tbdr');
validateattributes(refEdgePhiIntPhiIntPhiInt, {'numeric'}, {'size', [N N N 3]}, mfilename, 'refEdgePhiIntPhiIntPhiInt');

if nargin > 4
  ret = assembleMatEdgePhiIntPhiIntFuncDiscIntNu_withAreaNuE0Tbdr(refEdgePhiIntPhiIntPhiInt, dataDisc, areaNuE0Tbdr);
elseif isfield(g, 'areaNuE0T')
  ret = assembleMatEdgePhiIntPhiIntFuncDiscIntNu_withAreaNuE0T(g, markE0Tbdr, refEdgePhiIntPhiIntPhiInt, dataDisc);
else
  ret = assembleMatEdgePhiIntPhiIntFuncDiscIntNu_noAreaNuE0T(g, markE0Tbdr, refEdgePhiIntPhiIntPhiInt, dataDisc);
end % if
end % function
%
%===============================================================================
%> @brief Helper function for the case that assembleMatEdgePhiIntPhiIntFuncDiscIntNu()
%> was called with a precomputed field areaNuE0Tbdr.
%
function ret = assembleMatEdgePhiIntPhiIntFuncDiscIntNu_withAreaNuE0Tbdr(refEdgePhiIntPhiIntPhiInt, dataDisc, areaNuE0Tbdr)
% Extract dimensions
[K, N] = size(dataDisc);  

% Assemble matrices
ret = cell(2,1); 
ret{1} = sparse(K*N, K*N); 
ret{2} = sparse(K*N, K*N);
for n = 1 : 3
  for l = 1 : N
    ret{1} = ret{1} + kron(spdiags(areaNuE0Tbdr{n,1}.*dataDisc(:,l),0,K,K), refEdgePhiIntPhiIntPhiInt(:,:,l,n));
    ret{2} = ret{2} + kron(spdiags(areaNuE0Tbdr{n,2}.*dataDisc(:,l),0,K,K), refEdgePhiIntPhiIntPhiInt(:,:,l,n));
  end % for
end % for
end % function
%
%===============================================================================
%> @brief Helper function for the case that assembleMatEdgePhiIntPhiIntFuncDiscIntNu()
%> was called with no precomputed field areaNuE0Tbdr but parameter g
%> provides a precomputed field areaNuE0T.
%
function ret = assembleMatEdgePhiIntPhiIntFuncDiscIntNu_withAreaNuE0T(g, markE0Tbdr, refEdgePhiIntPhiIntPhiInt, dataDisc)
% Extract dimensions
[K, N] = size(dataDisc);  

% Assemble matrices
ret = cell(2,1); 
ret{1} = sparse(K*N, K*N); 
ret{2} = sparse(K*N, K*N);
for n = 1 : 3
  for l = 1 : N
    ret{1} = ret{1} + kron(spdiags(markE0Tbdr(:,n).*g.areaNuE0T{n,1}.*dataDisc(:,l),0,K,K), refEdgePhiIntPhiIntPhiInt(:,:,l,n));
    ret{2} = ret{2} + kron(spdiags(markE0Tbdr(:,n).*g.areaNuE0T{n,2}.*dataDisc(:,l),0,K,K), refEdgePhiIntPhiIntPhiInt(:,:,l,n));
  end % for
end % for
end % function
%
%===============================================================================
%> @brief Helper function for the case that assembleMatEdgePhiIntPhiIntFuncDiscIntNu()
%> was called with no precomputed field areaNuE0Tbdr and parameter g
%> provides no precomputed field areaNuE0T.
%
function ret = assembleMatEdgePhiIntPhiIntFuncDiscIntNu_noAreaNuE0T(g, markE0Tbdr, refEdgePhiIntPhiIntPhiInt, dataDisc)
% Extract dimensions
[K, N] = size(dataDisc);  

% Assemble matrices
ret = cell(2,1); 
ret{1} = sparse(K*N, K*N); 
ret{2} = sparse(K*N, K*N);
for n = 1 : 3
  RDkn = markE0Tbdr(:,n) .* g.areaE0T(:,n);
  for l = 1 : N
    ret{1} = ret{1} + kron(spdiags(RDkn.*g.nuE0T(:,n,1).*dataDisc(:,l),0,K,K), refEdgePhiIntPhiIntPhiInt(:,:,l,n));
    ret{2} = ret{2} + kron(spdiags(RDkn.*g.nuE0T(:,n,2).*dataDisc(:,l),0,K,K), refEdgePhiIntPhiIntPhiInt(:,:,l,n));
  end % for
end % for
end % function