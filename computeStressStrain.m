function computeStressStrain

global elements u nel coordinates MAT isPipe
global axialForce bendingMoment torsionalForce shearForce

for i=1:nel
    matNum = elements(i,1);
    dirNum = elements(i,2);
    % get material and section properties
    prop = cell2mat(MAT(matNum));
    E = prop(1); % Elastic modulus
    G = prop(2); % Shear modulus
    if isPipe %true
        % outer radius
        ro = prop(3)/2;
        % wall thickness
        tk = prop(4);
        % internal radius
        ri = ro - tk;
        %
        A = pi * ( ro^2 - ri^2 ); % cross sectional area
        I1 = (pi/4) * ( ro^4 - ri^4 ); % moment of iniertia 1
        I2 = I1; % moment of iniertia 2
        J = I1 + I2; % polar moment of inertia
    else % false
        A = prop(3); % cross sectional area
        I1 = prop(4); % moment of iniertia 1
        I2 = prop(5); % moment of iniertia 2
        J = I1 + I2; % polar moment of inertia
    end
    
    % 1 point formula - degree of precision 1
    % r = 0 w = 1
    xe = coordinates(elements(i,3:4),:);
    de = u(:,elements(i,3:4));
    %
    ue = zeros(12,1);
    for a=1:2 % loop over local nodes
        for j = 1:3 % loop over dimension
            ue(6*a-6+j) = de(j,a);
            ue(6*a-3+j) = de(j+3,a);
        end
    end
    %
    [ T ] = computeBeamDirection(dirNum,xe);
    % transform global to local
    ue = T.'*ue;
    % compute element length
    x1 = xe(1,1);
    x2 = xe(2,1);
    %
    y1 = xe(1,2);
    y2 = xe(2,2);
    %
    z1 = xe(1,3);
    z2 = xe(2,3);
    %
    he = sqrt( (x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2 );
    % ------------
    % bending
    % ------------
    dN1 = -1/he;
    dN2 = 1/he;
    % curvature matrix
    Bb = zeros(2,12);
    Bb(1,4) = dN1;
    Bb(1,10) = dN2;
    %
    Bb(2,5) = dN1;
    Bb(2,11) = dN2;
    %
    kappa = Bb*ue; % curvature (2 x 1)
    if isPipe % true
        do = 2*ro; % outer diameter
        S = pi*do^4/32; % section modulus
        bendingMoment(i,1) = E*I1*kappa(1)/S; % maximum bending stress
        bendingMoment(i,2) = -E*I2*kappa(2)/S; % maximum bending stress
    else
        bendingMoment(i,1) = E*I1*kappa(1);
        bendingMoment(i,2) = -E*I2*kappa(2);
    end
    %
    % ----------
    % shear
    % ----------
    % shear deformation matrix
    N1 = 0.5; N2 = 0.5; % one-point quadrature
    Bs = zeros(2,12);
    Bs(1,1) = dN1;
    Bs(1,5) = -N1;
    Bs(1,7) = dN2;
    Bs(1,11) = -N2;
    %
    Bs(2,2) = dN1;
    Bs(2,4) = -N1;
    Bs(2,8) = dN2;
    Bs(2,11) = N2;
    %
    shearStrain = Bs*ue; % shear strain (2 x 1)
    if isPipe % true
        C = (ro^2 + 2*ro*ri + ri^2)/(ro^2+ri^2);
        shearForce(i,1) = (4/3)*G*shearStrain(1)*C;
        shearForce(i,1) = (4/3)*G*shearStrain(2)*C;
    else
        shearForce(i,1) = G*A*shearStrain(1);
        shearForce(i,1) = G*A*shearStrain(2);
    end
    %
    % ----------
    % axial
    % -----------
    % axial matrix
    B = zeros(1,12);
    B(1,3) = dN1;
    B(1,9) = dN2;
    %
    axialStrain = B*ue; % axial strain (1 x 1)
    if isPipe % true
        axialForce(i) = E*axialStrain;
    else
        axialForce(i) = E*A*axialStrain;
    end
    %
    % ------------
    % torsional
    % ------------
    % axial matrix
    Bt = zeros(1,12);
    Bt(1,6) = dN1;
    Bt(1,12) = dN2;
    %
    torsionalStrain = Bt*ue; % torsional strain (1 x 1)
    if isPipe % true
        torsionalForce(i) = G*torsionalStrain*ro;
    else
        torsionalForce(i) = G*J*torsionalStrain;
    end
    %
end

end