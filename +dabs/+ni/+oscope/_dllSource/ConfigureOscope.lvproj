<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="15008000">
	<Item Name="My Computer" Type="My Computer">
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="OscopeAPI" Type="Folder">
			<Item Name="Device Session.lvclass" Type="LVClass" URL="../OscopeAPI/Device Session.lvclass"/>
		</Item>
		<Item Name="CheckOverload.vi" Type="VI" URL="../CheckOverload.vi"/>
		<Item Name="ClearOverload.vi" Type="VI" URL="../ClearOverload.vi"/>
		<Item Name="ConfigureChannel.vi" Type="VI" URL="../ConfigureChannel.vi"/>
		<Item Name="ConfigureChannels.vi" Type="VI" URL="../ConfigureChannels.vi"/>
		<Item Name="ConfigureSampleClock.vi" Type="VI" URL="../ConfigureSampleClock.vi"/>
		<Item Name="OscopeSession.vi" Type="VI" URL="../OscopeSession.vi"/>
		<Item Name="Post-Build Action.vi" Type="VI" URL="../Post-Build Action.vi"/>
		<Item Name="SessionActive.vi" Type="VI" URL="../SessionActive.vi"/>
		<Item Name="StartSession.vi" Type="VI" URL="../StartSession.vi"/>
		<Item Name="Dependencies" Type="Dependencies">
			<Item Name="instr.lib" Type="Folder">
				<Item Name="niHSAI 5170 CPLD v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/5170 CPLD/v1/Host/niHSAI 5170 CPLD v1 Host.llb/niHSAI 5170 CPLD v1 Host.lvlib"/>
				<Item Name="niHSAI AD5623 v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/AD5623/v1/Host/niHSAI AD5623 v1 Host.llb/niHSAI AD5623 v1 Host.lvlib"/>
				<Item Name="niHSAI AD9250 v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/AD9250/v1/Host/niHSAI AD9250 v1 Host.llb/niHSAI AD9250 v1 Host.lvlib"/>
				<Item Name="niHSAI BC 1 Config v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Config/BC 1/v1/Host/niHSAI BC 1 Config v1 Host.lvlib"/>
				<Item Name="niHSAI BC1 Registers v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/BC1/v1/Host/niHSAI BC1 Registers v1 Host.llb/niHSAI BC1 Registers v1 Host.lvlib"/>
				<Item Name="niHSAI Cal Data Common v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Common/v1/Host/niHSAI Cal Data Common v1 Host.lvlib"/>
				<Item Name="niHSAI Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Interface/v1/Host/Cal Data/niHSAI Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Common Config v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Config/Common/niHSAI Common Config v1 Host.lvlib"/>
				<Item Name="niHSAI Config v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Config/Interface/v1/Host/niHSAI Config v1 Host.lvclass"/>
				<Item Name="niHSAI DC Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Interface/v1/Host/DC/niHSAI DC Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Dev Caps v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Dev Caps/Base/v1/Host/niHSAI Dev Caps v1 Host.lvclass"/>
				<Item Name="niHSAI Group A Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Group A/v1/Host/Cal Data/niHSAI Group A Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Group A Cal Map v1 Shared Private.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Group A/v1/Host/Cal Map/niHSAI Group A Cal Map v1 Shared Private.lvlib"/>
				<Item Name="niHSAI Group A Config v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Config/Group A/v1/Host/Main/niHSAI Group A Config v1 Host.lvclass"/>
				<Item Name="niHSAI Group A DC Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Group A/v1/Host/DC/niHSAI Group A DC Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Group A Dev Caps v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Dev Caps/Group A/v1/Host/niHSAI Group A Dev Caps v1 Host.lvlib"/>
				<Item Name="niHSAI Group A Dig Correction Regs v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/Digital Correction/v1/Host/niHSAI Group A Dig Correction Regs v1 Host.llb/niHSAI Group A Dig Correction Regs v1 Host.lvlib"/>
				<Item Name="niHSAI Group A LVFPGA Registers v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/Group A LVFPGA/v1/Host/niHSAI Group A LVFPGA Registers v1 Host.llb/niHSAI Group A LVFPGA Registers v1 Host.lvlib"/>
				<Item Name="niHSAI Group A Phase Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Group A/v1/Host/Phase/niHSAI Group A Phase Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Group A Phase DAC v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Config/Group A/v1/Host/Phase/niHSAI Group A Phase DAC v1 Host.lvclass"/>
				<Item Name="niHSAI Group A Settling Regs v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/Group A Settling/v1/Host/niHSAI Group A Settling Regs v1 Host.llb/niHSAI Group A Settling Regs v1 Host.lvlib"/>
				<Item Name="niHSAI Group A TDC Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Group A/v1/Host/TDC/niHSAI Group A TDC Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Group A Timebase Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Group A/v1/Host/Timebase/niHSAI Group A Timebase Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI LMK0482x v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Register Maps/LMK0482x/v1/Host/niHSAI LMK0482x v1 Host.llb/niHSAI LMK0482x v1 Host.lvlib"/>
				<Item Name="niHSAI Phase Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Interface/v1/Host/Phase/niHSAI Phase Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI TDC Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Interface/v1/Host/TDC/niHSAI TDC Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Timebase Cal Data v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/HSAI-RIO/Cal Data/Interface/v1/Host/Timebase/niHSAI Timebase Cal Data v1 Host.lvclass"/>
				<Item Name="niHSAI Types v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Types/v1/Host/niHSAI Types v1 Host.lvlib"/>
				<Item Name="niHSAI Utilities v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/HSAI-RIO/Utilities/v1/Host/niHSAI Utilities v1 Host.lvlib"/>
				<Item Name="niInstr Data Manipulation v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/_niInstr/Data Manipulation/v1/Host/niInstr Data Manipulation v1 Host.lvlib"/>
				<Item Name="niInstr Data Trigger v1 Shared.lvlib" Type="Library" URL="/&lt;instrlib&gt;/_niInstr/Data Trigger/v1/Shared/niInstr Data Trigger v1 Shared.lvlib"/>
				<Item Name="niInstr FIFO Register Bus v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/_niInstr/FIFO Register Bus/v1/Host/niInstr FIFO Register Bus v1 Host.lvclass"/>
				<Item Name="niInstr FIFO Register Bus v1 Shared.lvlib" Type="Library" URL="/&lt;instrlib&gt;/_niInstr/FIFO Register Bus/v1/Shared/niInstr FIFO Register Bus v1 Shared.lvlib"/>
				<Item Name="niInstr Instruction Framework Common v1 Host.lvlib" Type="Library" URL="/&lt;instrlib&gt;/_niInstr/Instruction Framework/v1/Host/Common/niInstr Instruction Framework Common v1 Host.lvlib"/>
				<Item Name="niInstr Instruction Framework Context v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/_niInstr/Instruction Framework/v1/Host/Instruction Framework Context/niInstr Instruction Framework Context v1 Host.lvclass"/>
				<Item Name="niInstr Instruction Queue v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/_niInstr/Instruction Framework/v1/Host/Instruction Queue/niInstr Instruction Queue v1 Host.lvclass"/>
				<Item Name="niInstr Instruction Target v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/_niInstr/Instruction Framework/v1/Host/Instruction Target/niInstr Instruction Target v1 Host.lvclass"/>
				<Item Name="niInstr Register Bus Queue v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/_niInstr/Instruction Framework/v1/Host/Register Bus Queue/niInstr Register Bus Queue v1 Host.lvclass"/>
				<Item Name="niInstr Subsystem Map v1 Host.lvclass" Type="LVClass" URL="/&lt;instrlib&gt;/_niInstr/Instruction Framework/v1/Host/Subsystem Map/niInstr Subsystem Map v1 Host.lvclass"/>
			</Item>
			<Item Name="vi.lib" Type="Folder">
				<Item Name="Clear Errors.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Clear Errors.vi"/>
				<Item Name="Error Cluster From Error Code.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Error Cluster From Error Code.vi"/>
				<Item Name="ni5170 Driver Interface.lvlib" Type="Library" URL="/&lt;vilib&gt;/LabVIEW Targets/FPGA/Digitizers/Driver Interface/5170/ni5170 Driver Interface.lvlib"/>
				<Item Name="NI_AALPro.lvlib" Type="Library" URL="/&lt;vilib&gt;/Analysis/NI_AALPro.lvlib"/>
				<Item Name="niHSAI Plugin Interface.lvlib" Type="Library" URL="/&lt;vilib&gt;/LabVIEW Targets/FPGA/Digitizers/Plugin Interface/niHSAI Plugin Interface.lvlib"/>
			</Item>
			<Item Name="ni5170u.dll" Type="Document" URL="ni5170u.dll">
				<Property Name="NI.PreserveRelativePath" Type="Bool">true</Property>
			</Item>
			<Item Name="NiFpgaLv.dll" Type="Document" URL="NiFpgaLv.dll">
				<Property Name="NI.PreserveRelativePath" Type="Bool">true</Property>
			</Item>
			<Item Name="niLVDataManip.dll" Type="Document" URL="/&lt;resource&gt;/niLVDataManip.dll"/>
		</Item>
		<Item Name="Build Specifications" Type="Build">
			<Item Name="ConfigureOscopeDll" Type="DLL">
				<Property Name="App_copyErrors" Type="Bool">true</Property>
				<Property Name="App_INI_aliasGUID" Type="Str">{216FDC4D-6383-4255-950F-C4004576F408}</Property>
				<Property Name="App_INI_GUID" Type="Str">{C3121589-727B-4433-99BB-C7F6F2DFAFAC}</Property>
				<Property Name="App_serverConfig.httpPort" Type="Int">8002</Property>
				<Property Name="Bld_autoIncrement" Type="Bool">true</Property>
				<Property Name="Bld_buildCacheID" Type="Str">{56F75B2B-DF46-4081-B43F-F5C1B951B30E}</Property>
				<Property Name="Bld_buildSpecName" Type="Str">ConfigureOscopeDll</Property>
				<Property Name="Bld_excludeInlineSubVIs" Type="Bool">true</Property>
				<Property Name="Bld_excludeLibraryItems" Type="Bool">true</Property>
				<Property Name="Bld_excludePolymorphicVIs" Type="Bool">true</Property>
				<Property Name="Bld_localDestDir" Type="Path">../Build</Property>
				<Property Name="Bld_localDestDirType" Type="Str">relativeToProject</Property>
				<Property Name="Bld_modifyLibraryFile" Type="Bool">true</Property>
				<Property Name="Bld_postActionVIID" Type="Ref">/My Computer/Post-Build Action.vi</Property>
				<Property Name="Bld_previewCacheID" Type="Str">{FF19E514-881B-4064-A1C6-AF5A7DAB8483}</Property>
				<Property Name="Bld_version.build" Type="Int">4</Property>
				<Property Name="Bld_version.major" Type="Int">1</Property>
				<Property Name="Destination[0].destName" Type="Str">ConfigureOscope.dll</Property>
				<Property Name="Destination[0].path" Type="Path">../Build/NI_AB_PROJECTNAME.dll</Property>
				<Property Name="Destination[0].path.type" Type="Str">relativeToProject</Property>
				<Property Name="Destination[0].preserveHierarchy" Type="Bool">true</Property>
				<Property Name="Destination[0].type" Type="Str">App</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../Build/data</Property>
				<Property Name="Destination[1].path.type" Type="Str">relativeToProject</Property>
				<Property Name="DestinationCount" Type="Int">2</Property>
				<Property Name="Dll_compatibilityWith2011" Type="Bool">false</Property>
				<Property Name="Dll_delayOSMsg" Type="Bool">true</Property>
				<Property Name="Dll_headerGUID" Type="Str">{47D38BA4-C851-4016-8A73-3CBC6B7794E4}</Property>
				<Property Name="Dll_includeHeaders" Type="Bool">true</Property>
				<Property Name="Dll_libGUID" Type="Str">{240E9BDC-5264-4727-AB17-E20F71BBE9C8}</Property>
				<Property Name="Source[0].itemID" Type="Str">{CED85E45-B2B5-4560-B86A-F0CC251B708D}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[0]VIProtoDir" Type="Int">4</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[0]VIProtoInputIdx" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[0]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[0]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[0]VIProtoName" Type="Str">return value</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[0]VIProtoOutputIdx" Type="Int">19</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[0]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[1]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[1]VIProtoInputIdx" Type="Int">0</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[1]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[1]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[1]VIProtoName" Type="Str">deviceAddress</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[1]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[1]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]CallingConv" Type="Int">1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]Name" Type="Str">startSession</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]VIProtoInputIdx" Type="Int">1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]VIProtoName" Type="Str">bitfilePath</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfo[2]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfoCPTM" Type="Bin">&amp;1#!!!!!!!A!'%!Q`````QZE:8:J9W5A172E=G6T=Q!!&amp;E!Q`````QRC;82G;7RF)&amp;"B&gt;'A!!!1!!!!-1#%'=X2B&gt;(6T!!!,1!-!"'.P:'5!!""!-0````]'=W^V=G.F!!!71&amp;!!!Q!$!!1!"1F&amp;=H*P=C"0&gt;81!B!$Q!"1!!!!"!!)!!A!#!!)!!A!#!!)!!A!#!!)!!A!#!!)!!A!#!!)!!A!'!Q!"%!!"#A!!!1I!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!E!!!!!!1!(</Property>
				<Property Name="Source[1].ExportedVI.VIProtoInfoVIProtoItemCount" Type="Int">3</Property>
				<Property Name="Source[1].itemID" Type="Ref">/My Computer/StartSession.vi</Property>
				<Property Name="Source[1].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[1].type" Type="Str">ExportedVI</Property>
				<Property Name="Source[2].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]CallingConv" Type="Int">1</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]Name" Type="Str">clearOverload</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]VIProtoDir" Type="Int">1</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]VIProtoInputIdx" Type="Int">-1</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]VIProtoName" Type="Str">return value</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]VIProtoOutputIdx" Type="Int">1</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfo[0]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfoCPTM" Type="Bin">&amp;1#!!!!!!!=!$%!B"H.U982V=Q!!#U!$!!2D&lt;W2F!!!11$$`````"H.P&gt;8*D:1!!&amp;E"1!!-!!!!"!!)*28*S&lt;X)A4X6U!"F!"Q!3&lt;7FO)(&gt;B;81A&gt;'FN:3!I&lt;8-J!!!%!!!!3!$Q!!I!!Q!%!!5!"1!&amp;!!5!"1!&amp;!!5!"1-!!.!!!!E!!!!*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1!'</Property>
				<Property Name="Source[2].ExportedVI.VIProtoInfoVIProtoItemCount" Type="Int">1</Property>
				<Property Name="Source[2].itemID" Type="Ref">/My Computer/ClearOverload.vi</Property>
				<Property Name="Source[2].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[2].type" Type="Str">ExportedVI</Property>
				<Property Name="Source[3].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[0]VIProtoDir" Type="Int">4</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[0]VIProtoInputIdx" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[0]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[0]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[0]VIProtoName" Type="Str">return value</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[0]VIProtoOutputIdx" Type="Int">19</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[0]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[1]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[1]VIProtoInputIdx" Type="Int">2</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[1]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[1]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[1]VIProtoName" Type="Str">channel</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[1]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[1]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[2]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[2]VIProtoInputIdx" Type="Int">3</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[2]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[2]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[2]VIProtoName" Type="Str">inputRangeVpp</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[2]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[2]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[3]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[3]VIProtoInputIdx" Type="Int">4</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[3]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[3]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[3]VIProtoName" Type="Str">enableFilter</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[3]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[3]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]CallingConv" Type="Int">1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]Name" Type="Str">configureChannel</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]VIProtoInputIdx" Type="Int">5</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]VIProtoName" Type="Str">acCoupling</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfo[4]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfoCPTM" Type="Bin">&amp;1#!!!!!!!I!"!!!!!V!"Q!(9WBB&lt;GZF&lt;!!81!I!%7FO=(6U)&amp;*B&lt;G&gt;F)#B7=(!J!"*!)1VF&lt;G&amp;C&lt;'5A2GFM&gt;'6S!""!)1NB9S"$&lt;X6Q&lt;'FO:Q!-1#%'=X2B&gt;(6T!!!,1!-!"'.P:'5!!""!-0````]'=W^V=G.F!!!71&amp;!!!Q!&amp;!!9!"QF&amp;=H*P=C"0&gt;81!B!$Q!"1!!!!!!!%!!A!$!!1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!)!Q!"%!!!!!!!!!!!!!!)!!!!#!!!!!A!!!!)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!E!!!!!!1!*</Property>
				<Property Name="Source[3].ExportedVI.VIProtoInfoVIProtoItemCount" Type="Int">5</Property>
				<Property Name="Source[3].itemID" Type="Ref">/My Computer/ConfigureChannel.vi</Property>
				<Property Name="Source[3].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[3].type" Type="Str">ExportedVI</Property>
				<Property Name="Source[4].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[0]VIProtoDir" Type="Int">4</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[0]VIProtoInputIdx" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[0]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[0]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[0]VIProtoName" Type="Str">return value</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[0]VIProtoOutputIdx" Type="Int">19</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[0]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[1]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[1]VIProtoInputIdx" Type="Int">2</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[1]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[1]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[1]VIProtoName" Type="Str">nChannels</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[1]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[1]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[2]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[2]VIProtoInputIdx" Type="Int">3</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[2]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[2]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[2]VIProtoName" Type="Str">inputRangeVpp</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[2]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[2]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[3]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[3]VIProtoInputIdx" Type="Int">4</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[3]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[3]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[3]VIProtoName" Type="Str">enableFilter</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[3]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[3]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]CallingConv" Type="Int">1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]Name" Type="Str">configureChannels</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]VIProtoInputIdx" Type="Int">5</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]VIProtoName" Type="Str">acCoupling</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfo[4]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfoCPTM" Type="Bin">&amp;1#!!!!!!!I!"!!!!"&amp;!!Q!+&lt;C"$;'&amp;O&lt;G6M=Q!!&amp;U!+!"&amp;J&lt;H"V&gt;#"397ZH:3!I6H"Q+1!31#%.:7ZB9GRF)%:J&lt;(2F=A!11#%,97-A1W^V='RJ&lt;G=!$%!B"H.U982V=Q!!#U!$!!2D&lt;W2F!!!11$$`````"H.P&gt;8*D:1!!&amp;E"1!!-!"1!'!!=*28*S&lt;X)A4X6U!)1!]!!5!!!!!!!"!!)!!Q!%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#!-!!2!!!!!!!!!!!!!!#A!!!!A!!!!)!!!!#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*!!!!!!%!#1</Property>
				<Property Name="Source[4].ExportedVI.VIProtoInfoVIProtoItemCount" Type="Int">5</Property>
				<Property Name="Source[4].itemID" Type="Ref">/My Computer/ConfigureChannels.vi</Property>
				<Property Name="Source[4].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[4].type" Type="Str">ExportedVI</Property>
				<Property Name="Source[5].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[0]VIProtoDir" Type="Int">4</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[0]VIProtoInputIdx" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[0]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[0]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[0]VIProtoName" Type="Str">return value</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[0]VIProtoOutputIdx" Type="Int">19</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[0]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[1]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[1]VIProtoInputIdx" Type="Int">7</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[1]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[1]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[1]VIProtoName" Type="Str">enableExternalClock</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[1]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[1]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]CallingConv" Type="Int">1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]Name" Type="Str">configureSampleClock</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]VIProtoDir" Type="Int">0</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]VIProtoInputIdx" Type="Int">9</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]VIProtoName" Type="Str">externalClockRateHz</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]VIProtoOutputIdx" Type="Int">-1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfo[2]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfoCPTM" Type="Bin">&amp;1#!!!!!!!A!"!!!!"J!)26F&lt;G&amp;C&lt;'5A28BU:8*O97QA1WRP9WM!(U!+!"BF?(2F=GZB&lt;#"$&lt;'^D;S"3982F)#B)?CE!!!R!)1:T&gt;'&amp;U&gt;8-!!!N!!Q!%9W^E:1!!%%!Q`````Q:T&lt;X6S9W5!!":!5!!$!!-!"!!&amp;#56S=G^S)%^V&gt;!#%!0!!&amp;!!!!!!!!!!!!!!!!!!!!!%!!!!#!!!!!!!!!!!!!!!!!!!!!!!!!!9$!!%1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#!!!!!!!!!!)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#1!!!!!"!!=</Property>
				<Property Name="Source[5].ExportedVI.VIProtoInfoVIProtoItemCount" Type="Int">3</Property>
				<Property Name="Source[5].itemID" Type="Ref">/My Computer/ConfigureSampleClock.vi</Property>
				<Property Name="Source[5].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[5].type" Type="Str">ExportedVI</Property>
				<Property Name="Source[6].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]CallingConv" Type="Int">1</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]Name" Type="Str">sessionActive</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]VIProtoDir" Type="Int">1</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]VIProtoInputIdx" Type="Int">-1</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]VIProtoName" Type="Str">return value</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]VIProtoOutputIdx" Type="Int">2</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfo[0]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfoCPTM" Type="Bin">&amp;1#!!!!!!!1!"!!!!!V!"1!'17.U;8:F!!!-1#%'17.U;8:F!!")!0!!#A!!!!!!!1!#!!!!!!!!!!!!!!!!!Q!!U!!!!!!!!!!!!!!*!!!!#1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"!!-</Property>
				<Property Name="Source[6].ExportedVI.VIProtoInfoVIProtoItemCount" Type="Int">1</Property>
				<Property Name="Source[6].itemID" Type="Ref">/My Computer/SessionActive.vi</Property>
				<Property Name="Source[6].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[6].type" Type="Str">ExportedVI</Property>
				<Property Name="Source[7].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]CallingConv" Type="Int">1</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]Name" Type="Str">checkOverload</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]VIProtoDir" Type="Int">4</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]VIProtoInputIdx" Type="Int">-1</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]VIProtoLenInput" Type="Int">-1</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]VIProtoLenOutput" Type="Int">-1</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]VIProtoName" Type="Str">return value</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]VIProtoOutputIdx" Type="Int">0</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfo[0]VIProtoPassBy" Type="Int">1</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfoCPTM" Type="Bin">&amp;1#!!!!!!!9!$%!B"H.U982V=Q!!#U!$!!2D&lt;W2F!!!11$$`````"H.P&gt;8*D:1!!&amp;E"1!!-!!!!"!!)*28*S&lt;X)A4X6U!!1!!!")!0!!#A!$!!1!"!!%!!1!"!!%!!1!"!!%!Q!!U!!!#1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"!!5</Property>
				<Property Name="Source[7].ExportedVI.VIProtoInfoVIProtoItemCount" Type="Int">1</Property>
				<Property Name="Source[7].itemID" Type="Ref">/My Computer/CheckOverload.vi</Property>
				<Property Name="Source[7].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[7].type" Type="Str">ExportedVI</Property>
				<Property Name="SourceCount" Type="Int">8</Property>
				<Property Name="TgtF_enableDebugging" Type="Bool">true</Property>
				<Property Name="TgtF_fileDescription" Type="Str">ConfigureOscopeDll</Property>
				<Property Name="TgtF_internalName" Type="Str">ConfigureOscopeDll</Property>
				<Property Name="TgtF_legalCopyright" Type="Str">Copyright © 2015 </Property>
				<Property Name="TgtF_productName" Type="Str">ConfigureOscopeDll</Property>
				<Property Name="TgtF_targetfileGUID" Type="Str">{88E994C9-7E8C-46C9-BBAD-C327123D7B75}</Property>
				<Property Name="TgtF_targetfileName" Type="Str">ConfigureOscope.dll</Property>
			</Item>
		</Item>
	</Item>
</Project>
