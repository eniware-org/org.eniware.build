Eniware Edge Framework Packages
============================

This folder contains some packages of the EniwareEdge platform, which can
be used to deploy new Edges.

The **base-equinox-Edge.tgz** package contains the core platform based
on the Eclipse Equinox OSGi container. Expand this package into the
*eniware* user's home directory to create the base platform.

Other packages included here add additional features to the base Edge.
They must be expanded from within the `app` directory created by the
base package. That is, the following steps illustrate adding an extra
package to the base platform:

		tar xzf /tmp/base-equinox-Edge.tgz
		cd app
		tar xzf /tmp/centameter-consumption-Edge-bundles.tgz
  
System Startup Scripts
----------------------

This folder also contains system startup scripts that can be used as
a starting point for starting the Edge as a service. These files are
shell scripts, named `*.sh`. Be sure to use the correct startup script
for the base Edge's OSGi container you've deployed. For example if the
base Edge package name contains `equinox` then the startup script name
should, too.
