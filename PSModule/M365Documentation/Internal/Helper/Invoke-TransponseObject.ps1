function Invoke-TransposeObject { 
	<#
	.SYNOPSIS
	Transpose properties of objects from columns to rows.
	.DESCRIPTION
	Transpose properties of objects from columns to rows. Useful when the order displayed in a GridView (with
	Out-GridView) or in a CSV file (with Export-Csv) should be rotated.
	It uses the name property as new property names (column headers) if it exists.
	.INPUTS
	Object
	.OUTPUTS
	Transposed object
	.EXAMPLE
	dir | Transpose-Object | Out-GridView

	Shows directory listing with a column instead of a row for every file/directory
	.EXAMPLE
	ps | Transpose-Object | Export-Csv Processes.csv -Delimiter ';' -NoTypeInformation

	Creates a CSV file with a column instead of a row for every process
	.NOTES
	Name: Transpose-Object
	Author: Markus Scholtes
	Version: 1.0 - Initial version
	Creation Date: 01/11/2019
	#>
	[OutputType('System.Object[]')]
	[CmdletBinding()]
	Param([OBJECT][Parameter(ValueFromPipeline = $TRUE)]$InputObject)

	BEGIN
	{ # initialize variables just to be "clean"
		$Props = @()
		$PropNames = @()
		$InstanceNames = @()
	}

	PROCESS
	{
		if ($Props.Length -eq 0)
		{ # when first object in pipeline arrives retrieve its property names
				$PropNames = $InputObject.PSObject.Properties | Select-Object -ExpandProperty Name
				# and create a PSCustomobject in an array for each property
				$InputObject.PSObject.Properties | ForEach-Object{ $Props += New-Object -TypeName PSObject -Property @{Property = $_.Name} }
			}

			if ($InputObject.M_DisplayName)
			{ # does object have a "Name" property?
				$Property = $InputObject.M_DisplayName
			} else { # no, take object itself as property name
				$Property = $InputObject | Out-String
			}

			if ($InstanceNames -contains $Property)
			{ # does multiple occurence of name exist?
			$COUNTER = 0
				do { # yes, append a number in brackets to name
					$COUNTER++
					$Property = "$($InputObject.M_DisplayName) ({0})" -f $COUNTER
				} while ($InstanceNames -contains $Property)
			}
			# add current name to name list for next name check
			$InstanceNames += $Property

		# retrieve property values and add them to the property's PSCustomobject
		$COUNTER = 0
		$PropNames | ForEach-Object{
			if ($InputObject.($_))
			{ # property exists for current object
				$Props[$COUNTER] | Add-Member -Name $Property -Type NoteProperty -Value $InputObject.($_)
			} else { # property does not exist for current object, add $NULL value
				$Props[$COUNTER] | Add-Member -Name $Property -Type NoteProperty -Value $NULL
			}
				$COUNTER++
		}
	}

	END
	{
		# return collection of PSCustomobjects with property values
		$Props
	}
}