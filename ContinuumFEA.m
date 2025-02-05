function ContinuumFEA()
clear;
close all;

% MATERIAL PROPERTIES
E = 1; % Young modulus [N/m^2]
E2 = 0.001; % Young modulus [N/m^2]
v = 0.3; % Poisson's ratio
planeStrain = 1; % If 0, use plane stress

% GEOMETRY
Lx = 2; % Length of the structure in x-direction [m]
Ly = 1; % Length of the structure in y-direction [m]
D = 0.4; % Hole diameter [m]
cx = Lx/2; % Centre of circle
cy = Ly/2; % Centre of circle

% MESH SIZING
nx = 19; % # elements in x
ny = 19; % # elements in y
Dx = Lx/nx; % size of the element along x
Dy = Ly/ny; % size of the element along y

% LOADING
q = -0.1; % The distributed load at the top surface in [N/m]

% PLOT PARAMETERS
nms = 3; % node marker size for displacements plot

% Nodes
N = (nx+1)*(ny+1); % total n. of nodes
ix = [1:nx+1]; % Node grid
iy = [1:ny+1]; % Node grid

% Node coordinates
x = (ix-1)*Dx;
y = (iy-1)*Dy;
[xn,yn] = meshgrid(x,y);

if planeStrain
    % Plane Strain Stiffness Matrices
    Em = [(1-v) v 0;
        v (1-v) 0;
        0 0 (1-2*v)/2]*E/((1+v)*(1-2*v));
    Em2 = [(1-v) v 0;
        v (1-v) 0;
        0 0 (1-2*v)/2]*E2/((1+v)*(1-2*v));
else
    % Plane Stress Stiffness Matrices
    Em = [1 v 0;
        v 1 0;
        0 0 (1-v)/2]*E/((1-v^2));
    Em2 = [1 v 0;
        v 1 0;
        0 0 (1-v)/2]*E2/((1-v^2));
end

% Gauss points
g(1,:) = 1/sqrt(3)*[-1,-1];
g(2,:) = 1/sqrt(3)*[1,-1];
g(3,:) = 1/sqrt(3)*[-1,1];
g(4,:) = 1/sqrt(3)*[1,1];

K = zeros(2*N,2*N);

for ex = 1:nx
    for ey = 1:ny
        zeroStiffness = 0;
        i = (ey-1)*(nx+1)+ex;
        j = i+nx+1;
        
        x1 = xn(ey,ex);
        x2 = xn(ey,ex+1);
        x3 = xn(ey+1,ex);
        x4 = xn(ey+1,ex+1);
        
        y1 = yn(ey,ex);
        y2 = yn(ey,ex+1);
        y3 = yn(ey+1,ex);
        y4 = yn(ey+1,ex+1);
        
        if doesLineIntersectCircle(x1,y1,x2,y2,cx,cy,D) ...
                || doesLineIntersectCircle(x1,y1,x3,y3,cx,cy,D)...
                ||doesLineIntersectCircle(x2,y2,x4,y4,cx,cy,D)...
                || doesLineIntersectCircle(x3,y3,x4,y4,cx,cy,D)
            zeroStiffness=1;
        end
        
        Kq = 0;
        
        % Quadrilateral Elements
        for gg = 1:4 % Four Gauss points
            xx = g(gg,1);
            yy = g(gg,2);
            Nxx = [-0.25*(1-yy), 0.25*(1-yy), -0.25*(1+yy), 0.25*(1+yy)];
            Nyy = [-0.25*(1-xx), -0.25*(1+xx), 0.25*(1-xx), 0.25*(1+xx)];
            J = [Nxx*[x1;x2;x3;x4], Nxx*[y1;y2;y3;y4]; ...
                Nyy*[x1;x2;x3;x4], Nyy*[y1;y2;y3;y4]];
            dJ = det(J);
            A= (1/dJ)*([J(2,2) -1*J(1,2) 0 0; 0 0 -1*J(2,1) J(1,1); ...
                -1*J(2,1) J(1,1) J(2,2) -1*J(1,2)]);
            G = [Nxx(1) 0 Nxx(2) 0 Nxx(3) 0 Nxx(4) 0;
                Nyy(1) 0 Nyy(2) 0 Nyy(3) 0 Nyy(4) 0;
                0 Nxx(1) 0 Nxx(2) 0 Nxx(3) 0 Nxx(4);
                0 Nyy(1) 0 Nyy(2) 0 Nyy(3) 0 Nyy(4)];
            B = A*G;
            
            if ~zeroStiffness
                Kq = Kq + B'*Em*B*dJ;
            else
                Kq = Kq + B'*Em2*B*dJ;
            end
            
            Bg(:,:,gg) = B;
        end
        edofs = [2*i-1,2*i,2*(i+1)-1,2*(i+1),2*j-1,2*j,2*(j+1)-1,2*(j+1)];
        K(edofs,edofs) = K(edofs,edofs)+Kq;
    end
end

% Boundary conditions
ixfix = [1:nx+1];
iyfix = 1;
ifix = (iyfix-1)*(nx+1)+ixfix;
fix_dofs = [2*(ifix)-1 2*(ifix)]; % both u and v are constrained

% Loads
f = zeros(length(K),1);

% Position of loaded nodes in the node grid
ixload = [1:nx+1];
iyload = (ny+1);
iload = (iyload-1)*(nx+1)+ixload;
load_dofs = 2*(iload); % Loading in the y direction
xload = [xn(iyload,1) xn(iyload,ixload) xn(iyload,end)];
f(load_dofs) = q*0.5*(xload(3:end)-xload(1:end-2));

% Solution
free_dofs = [1:length(K)];
free_dofs = setdiff(free_dofs,fix_dofs);

u = zeros(length(K),1);
f=f(free_dofs);
u(free_dofs) = K(free_dofs,free_dofs)\f;


% Plot results
figure(1)
clf;
hold on; grid on; grid minor
title('Nodes','fontsize',15)
plot(xn(iyfix,ixfix),yn(iyfix,ixfix),'rs','Markersize',6)
plot(xn(iyload,ixload),yn(iyload,ixload),'gv','MarkerEdgeColor',[0,0.7,0],'Markersize',6)
plot(xn,yn,'ko','Markersize',3)
circle(cx,cy,D/2, 1);
legend('fixed nodes','loaded nodes','all nodes','Location','NorthEastOutside')
axis equal;

figure(2)
title('Displacements','fontsize',15)
hold on; grid on; grid minor
grey = 0.6*[1 1 1];

for ey = 1:ny
    for ex = 1:nx
        x1 = xn(ey,ex);
        x2 = xn(ey,ex+1);
        x3 = xn(ey+1,ex);
        x4 = xn(ey+1,ex+1);
        
        y1 = yn(ey,ex);
        y2 = yn(ey,ex+1);
        y3 = yn(ey+1,ex);
        y4 = yn(ey+1,ex+1);
        
        i = (ey-1)*(nx+1)+ex;
        j = i+nx+1;
        
        u1 = u(2*i-1,1);
        u2 = u(2*(i+1)-1,1);
        u3 = u(2*j-1,1);
        u4 = u(2*(j+1)-1,1);
        
        v1 = u(2*i,1);
        v2 = u(2*(i+1),1);
        v3 = u(2*j,1);
        v4 = u(2*(j+1),1);
        
        uv = [u1;v1;u2;v2;u3;v3;u4;v4];
        % Average strains and stresses in the element 
        ev = 0;
        for gg = 1:4
            ev = ev+0.25*Bg(:,:,gg)*uv;
        end
        
        xc(ey,ex) = 0.25*(x1+x2+x3+x4);
        yc(ey,ex) = 0.25*(y1+y2+y3+y4);
        
        eev(ey,ex,:) = ev;
        sv(ey,ex,:) = Em*ev;
        % Von Mises Stress
        svm(ey,ex) = sqrt(sv(ey,ex,1)^2+sv(ey,ex,2)^2-sv(ey,ex,1)*sv(ey,ex,2)+3*sv(ey,ex,3)^2);
        
        % Quad Plotting
        if doesLineIntersectCircle(x1,y1,x2,y2,cx,cy,D)||...
                doesLineIntersectCircle(x1,y1,x3,y3,cx,cy,D)||...
                doesLineIntersectCircle(x2,y2,x4,y4,cx,cy,D)||...
                doesLineIntersectCircle(x3,y3,x4,y4,cx,cy,D)
            continue;
        end
        
        plot([x1,x2],[y1,y2],'k-o','Color',grey,'MarkerSize',nms,'markerfacecolor',grey)
        plot([x1,x3],[y1,y3],'k-o','Color',grey,'MarkerSize',nms,'markerfacecolor',grey)
        plot([x2,x4],[y2,y4],'k-o','Color',grey,'MarkerSize',nms,'markerfacecolor',grey)
        plot([x3,x4],[y3,y4],'k-o','Color',grey,'MarkerSize',nms,'markerfacecolor',grey)
        
        plot([x1+u1,x2+u2],[y1+v1,y2+v2],'b-o','MarkerSize',nms,'markerfacecolor','b')
        plot([x1+u1,x3+u3],[y1+v1,y3+v3],'b-o','MarkerSize',nms,'markerfacecolor','b')
        plot([x2+u2,x4+u4],[y2+v2,y4+v4],'b-o','MarkerSize',nms,'markerfacecolor','b')
        plot([x3+u3,x4+u4],[y3+v3,y4+v4],'b-o','MarkerSize',nms,'markerfacecolor','b')
    end
end

circle(cx,cy,D/2, 0);
axis equal

% Stresses
names = ['Sigma 11', 'Sigma 22', 'Sigma 12'];
for i = 1:3
    figure(10+i)
    contourf(xc,yc,sv(:,:,i))
    colorbar
    axis equal
    title(names((i-1)*8+1:(i-1)*8+8))
    circle(cx,cy,D/2, 1);
end

% Von Mises Stress
figure(20+i)
contourf(xc,yc,svm(:,:))
colorbar
axis equal
title('von Mises Stress')
circle(cx,cy,D/2, 1);

% Strains
names = ['Epsilon 11', 'Epsilon 22', 'Epsilon 12'];
for i = 1:3
    figure(30+i)
    contourf(xc,yc,eev(:,:,i))
    colorbar
    axis equal
    title(names((i-1)*10+1:(i-1)*10+10))
    circle(cx,cy,D/2, 1);
end
end

% Determines whether a line between two sets of points intersects a circle
% of a given centrepoint and diameter
function doesIntersect=doesLineIntersectCircle(x1,y1,x2,y2,cx,cy,d)
for n=0:10
    x=x1+(x2-x1)/10;
    y=y1+(y2-y1)/10;
    if euclideanDistance(x,y, cx,cy)<d/2
        doesIntersect=1;
        return
    end
end
doesIntersect=0;
end

% The euclidean distance between two sets of x and y points
function dist = euclideanDistance(x1,y1, x2, y2)
dist = sqrt((x2-x1)^2+(y2-y1)^2);
end

% Plots a circle at the given coordinates with radius r. Fills it with
% white if shouldFill==1
function circle(x,y,r, shouldFill)
hold on
th = 0:pi/50:2*pi;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
plot(xunit, yunit);
if shouldFill==1
    fill(xunit, yunit, 'w');
end
hold off
end





