
function InitializeWindow
{

	$dsdiag.ShowLog()
	$dsdiag.clear()
<# 
	$dsdiag.Trace("Breakpoint: Intialize Window starts now!")
	$_stop = "Breakpoint: Initalize Window starts now"
	$dsdiag.Inspect("_stop") #>

	#begin rules applying commonly
    $dsWindow.Title = SetWindowTitle		
    InitializeCategory
    InitializeNumSchm
    InitializeBreadCrumb
    InitializeFileNameValidation
	#end rules applying commonly
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#rules applying for Inventor
		}
		"AutoCADWindow"
		{
			#rules applying for AutoCAD
		}
	}
	$global:expandBreadCrumb = $true	

<# 	$dsdiag.Trace("Breakpoint: Window initalized")
	$_stop = "Breakpoint:  Window initalized"
	$dsdiag.Inspect("_stop") #>
}

function AddinLoaded
{
	#Executed when DataStandard is loaded in Inventor/AutoCAD
}

function AddinUnloaded
{
	#Executed when DataStandard is unloaded in Inventor/AutoCAD
}

function InitializeCategory()
{
	$dsdiag.trace("Ini Category")
	$dsdiag.trace($Prop["TCC Kategorie"].value)
    if ($Prop["_CreateMode"].Value)
    {
		$dsdiag.trace("IniCat	Create Mode")
		$dsdiag.trace("Save copy as = " + $Prop["_SaveCopyAsMode"].Value)
		if (-not $Prop["_SaveCopyAsMode"].Value)
		{
			#$dsdiag.trace("Save copy as")
            $Prop["_Category"].Value = $UIString["CAT1"]
        }
		$Prop["_Category"].value = $Prop["TCC Kategorie"].value
    }
<# 	$dsdiag.trace("Breakpoint: Category Initialized")
	$_stop="Breakpoint Stop: Category Initialized"
	$dsdiag.inspect("_stop") #>
}

function InitializeNumSchm()
{

	$dsdiag.trace("Ini NumSchem")
	#$dsdiag.trace($Prop["TCC Kategorie"].value)
	#$_stop="Breakpoint Stop: Ini NumSchem"
	#$dsdiag.trace($_.name)
	#$dsdiag.inspect("_stop")
	#Adopted from a DocumentService call, which always pulls FILE class numbering schemes
	$global:numSchems = @($vault.NumberingService.GetNumberingSchemes('FILE', 'Activated')) 
    if ($Prop["_CreateMode"].Value)
    {
		#$dsdiag.trace("Breakpoint: Create Mode")
		if (-not $Prop["_SaveCopyAsMode"].Value)
		{
			
			$Prop["_NumSchm"].Value = "Konstruktionsdateien"

			$Prop["_Category"].add_PropertyChanged({
				if ($_.PropertyName -eq "Value")
				{
					$numSchm = $numSchems | where {$_.Name -eq $Prop["_Category"].Value}
                    if($numSchm)
					{
                        $Prop["_NumSchm"].Value = $numSchm.Name
						$dsdiag.trace("Breakpoint: NumSchem true")
					}
					else
					{
						<# Action when all if and elseif conditions are false #>
						$dsdiag.trace("Breakpoint: NumSchem False")
						$Prop["_NumSchm"].Value = "Konstruktionsdateien"
					}
                }
			})
        }
		else
        {
            $Prop["_NumSchm"].Value = "None"
        }
    }
}

function GetVaultRootFolder()
{
    $mappedRootPath = $Prop["_VaultVirtualPath"].Value + $Prop["_WorkspacePath"].Value
    $mappedRootPath = $mappedRootPath -replace "\\", "/" -replace "//", "/"
    if ($mappedRootPath -eq '')
    {
        $mappedRootPath = '$'
    }
    return $vault.DocumentService.GetFolderByPath($mappedRootPath)
}

function SetWindowTitle
{
	$mWindowName = $dsWindow.Name
    switch($mWindowName)
 	{
  		"InventorFrameWindow"
  		{
   			$windowTitle = $UIString["LBL54"]
  		}
  		"InventorDesignAcceleratorWindow"
  		{
   			$windowTitle = $UIString["LBL50"]
  		}
  		"InventorPipingWindow"
  		{
   			$windowTitle = $UIString["LBL39"]
  		}
  		"InventorHarnessWindow"
  		{
   			$windowTitle = $UIString["LBL44"]
  		}
  		default #applies to InventorWindow and AutoCADWindow
  		{
   			if ($Prop["_CreateMode"].Value)
   			{
    			if ($Prop["_CopyMode"].Value)
    			{
     				$windowTitle = "$($UIString["LBL60"]) - $($Prop["_OriginalFileName"].Value)"
    			}
    			elseif ($Prop["_SaveCopyAsMode"].Value)
    			{
     				$windowTitle = "$($UIString["LBL72"]) - $($Prop["_OriginalFileName"].Value)"
    			}else
    			{
     				$windowTitle = "$($UIString["LBL24"]) - $($Prop["_OriginalFileName"].Value)"
    			}
   			}
   			else
   			{
    			$windowTitle = "$($UIString["LBL25"]) - $($Prop["_FileName"].Value)"
   			} 
  		}
 	}
  	return $windowTitle
}

function GetNumSchms
{
	$specialFiles = @(".DWG",".IDW",".IPN")
    if ($specialFiles -contains $Prop["_FileExt"].Value -and !$Prop["_GenerateFileNumber4SpecialFiles"].Value)
    {
        return $null
    }
	if (-Not $Prop["_EditMode"].Value)
    {
		if ($numSchems.Count -gt 1)
		{
			$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
		}
        if ($Prop["_SaveCopyAsMode"].Value)
        {
            $noneNumSchm = New-Object 'Autodesk.Connectivity.WebServices.NumSchm'
            $noneNumSchm.Name = $UIString["LBL77"]
            return $numSchems += $noneNumSchm
        }    
        return $numSchems
    }
}

function GetCategories
{
 	$dsdiag.trace("Get Categories")
	#$_stop="Breakpoint Stop: Get Categories"
	#$dsdiag.inspect("_stop")
	
	#$dsdiag.trace($Prop["Title"].value)
	
	return $Prop["_Category"].ListValues

}

function OnPostCloseDialog
{
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#rules applying for Inventor
		}
		"AutoCADWindow"
		{
			#rules applying for AutoCAD
			if ($Prop["_CreateMode"]) {
				#the default ACM Titleblocks expect the file name and drawing number as attribute values; adjust property(=attribute) names for custom titleblock definitions
				$dc = $dsWindow.DataContext
				$Prop["GEN-TITLE-DWG"].Value = $dc.PathAndFileNameHandler.FileName
				$Prop["GEN-TITLE-NR"].Value = $dc.PathAndFileNameHandler.FileNameNoExtension
			}
		}
		default
		{
			#rules applying commonly
		}
	}
}
