# 2026-03-18T14:32:28.827082800
import vitis

client = vitis.create_client()
client.set_workspace(path="TMP451_Space")

platform = client.create_platform_component(name = "TMP451_SYS_Pltfrm",hw_design = "$COMPONENT_LOCATION/../../../Hardware_Space/TMP451_CNTRLR/Outputs/TMP451_SYS_wrapper.xsa",os = "standalone",cpu = "ps7_cortexa9_0",domain_name = "standalone_ps7_cortexa9_0")

platform = client.get_component(name="TMP451_SYS_Pltfrm")
status = platform.build()

comp = client.create_app_component(name="TMP451_DRVR",platform = "$COMPONENT_LOCATION/../TMP451_SYS_Pltfrm/export/TMP451_SYS_Pltfrm/TMP451_SYS_Pltfrm.xpfm",domain = "standalone_ps7_cortexa9_0",template = "hello_world")

status = platform.build()

comp = client.get_component(name="TMP451_DRVR")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

