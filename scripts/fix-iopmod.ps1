#!/usr/bin/env pwsh

[CmdletBinding(DefaultParameterSetName = 'Path')]
Param (
  [SupportsWildCards()]
  [Parameter(
    Position = 0,
    ParameterSetName = 'Path',
    ValueFromPipeline = $false,
    ValueFromPipelineByPropertyName = $true
  )]
  [String[]]$Path = "SNDMOD.IRX",

  [Alias('LP')]
	[Alias('PSPath')]
  [Parameter(
    Position = 0,
    ParameterSetName = 'LiteralPath',
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true
  )]
  [String[]]$LiteralPath
)

Begin {
  class elf32_hdr {
    [Byte[]]  $ident
    [UInt16]  $type
    [UInt16]  $machine
    [UInt32]  $version
    [UInt32]  $entry
    [UInt32]  $phoff
    [UInt32]  $shoff
    [UInt32]  $flags
    [UInt16]  $ehsize
    [UInt16]  $phentsize
    [UInt16]  $phnum
    [UInt16]  $shentsize
    [UInt16]  $shnum
    [UInt16]  $shstrndx

    elf32_hdr([Byte[]] $value, [Int32] $startIndex) {
      $this.ident     = $value[0..15]
      $this.type      = [BitConverter]::ToUInt16( $value, $startIndex + 16)
      $this.machine   = [BitConverter]::ToUInt16( $value, $startIndex + 18)
      $this.version   = [BitConverter]::ToUInt32( $value, $startIndex + 20)
      $this.entry     = [BitConverter]::ToUInt32( $value, $startIndex + 24)
      $this.phoff     = [BitConverter]::ToUInt32( $value, $startIndex + 28)
      $this.shoff     = [BitConverter]::ToUInt32( $value, $startIndex + 32)
      $this.flags     = [BitConverter]::ToUInt32( $value, $startIndex + 36)
      $this.ehsize    = [BitConverter]::ToUInt16( $value, $startIndex + 40)
      $this.phentsize = [BitConverter]::ToUInt16( $value, $startIndex + 42)
      $this.phnum     = [BitConverter]::ToUInt16( $value, $startIndex + 44)
      $this.shentsize = [BitConverter]::ToUInt16( $value, $startIndex + 46)
      $this.shnum     = [BitConverter]::ToUInt16( $value, $startIndex + 48)
      $this.shstrndx  = [BitConverter]::ToUInt16( $value, $startIndex + 50)
    }
    [Byte[]]GetBytes() {
      return `
        $this.ident                                 +
        [BitConverter]::GetBytes($this.type       ) +
        [BitConverter]::GetBytes($this.machine    ) +
        [BitConverter]::GetBytes($this.version    ) +
        [BitConverter]::GetBytes($this.entry      ) +
        [BitConverter]::GetBytes($this.phoff      ) +
        [BitConverter]::GetBytes($this.shoff      ) +
        [BitConverter]::GetBytes($this.flags      ) +
        [BitConverter]::GetBytes($this.ehsize     ) +
        [BitConverter]::GetBytes($this.phentsize  ) +
        [BitConverter]::GetBytes($this.phnum      ) +
        [BitConverter]::GetBytes($this.shentsize  ) +
        [BitConverter]::GetBytes($this.shnum      ) +
        [BitConverter]::GetBytes($this.shstrndx   )
    }
  }

  class elf32_phdr {
    [UInt32]  $type
    [UInt32]  $offset
    [UInt32]  $vaddr
    [UInt32]  $paddr
    [UInt32]  $filesz
    [UInt32]  $memsz
    [UInt32]  $flags
    [UInt32]  $align
    
    elf32_phdr([Byte[]] $value, [Int32] $startIndex) {
      $this.type    = [BitConverter]::ToUInt32( $value, $startIndex)
      $this.offset  = [BitConverter]::ToUInt32( $value, $startIndex + 4)
      $this.vaddr   = [BitConverter]::ToUInt32( $value, $startIndex + 8)
      $this.paddr   = [BitConverter]::ToUInt32( $value, $startIndex + 12)
      $this.filesz  = [BitConverter]::ToUInt32( $value, $startIndex + 16)
      $this.memsz   = [BitConverter]::ToUInt32( $value, $startIndex + 20)
      $this.flags   = [BitConverter]::ToUInt32( $value, $startIndex + 24)
      $this.align   = [BitConverter]::ToUInt32( $value, $startIndex + 28)
    }
    [Byte[]]GetBytes() {
      return `
        [BitConverter]::GetBytes($this.type   ) +
        [BitConverter]::GetBytes($this.offset ) +
        [BitConverter]::GetBytes($this.vaddr  ) +
        [BitConverter]::GetBytes($this.paddr  ) +
        [BitConverter]::GetBytes($this.filesz ) +
        [BitConverter]::GetBytes($this.memsz  ) +
        [BitConverter]::GetBytes($this.flags  ) +
        [BitConverter]::GetBytes($this.align  )
    }
  }

  class elf32_shdr {
    [UInt32]  $name
    [UInt32]  $type
    [UInt32]  $flags
    [UInt32]  $addr
    [UInt32]  $offset
    [UInt32]  $size
    [UInt32]  $link
    [UInt32]  $info
    [UInt32]  $addralign
    [UInt32]  $entsize

    elf32_shdr([Byte[]] $value, [Int32] $startIndex) {
      $this.name      = [BitConverter]::ToUInt32( $value, $startIndex)
      $this.type      = [BitConverter]::ToUInt32( $value, $startIndex + 4)
      $this.flags     = [BitConverter]::ToUInt32( $value, $startIndex + 8)
      $this.addr      = [BitConverter]::ToUInt32( $value, $startIndex + 12)
      $this.offset    = [BitConverter]::ToUInt32( $value, $startIndex + 16)
      $this.size      = [BitConverter]::ToUInt32( $value, $startIndex + 20)
      $this.link      = [BitConverter]::ToUInt32( $value, $startIndex + 24)
      $this.info      = [BitConverter]::ToUInt32( $value, $startIndex + 28)
      $this.addralign = [BitConverter]::ToUInt32( $value, $startIndex + 32)
      $this.entsize   = [BitConverter]::ToUInt32( $value, $startIndex + 36)
    }
    [Byte[]]GetBytes() {
      return `
        [BitConverter]::GetBytes($this.name       ) +
        [BitConverter]::GetBytes($this.type       ) +
        [BitConverter]::GetBytes($this.flags      ) +
        [BitConverter]::GetBytes($this.addr       ) +
        [BitConverter]::GetBytes($this.offset     ) +
        [BitConverter]::GetBytes($this.size       ) +
        [BitConverter]::GetBytes($this.link       ) +
        [BitConverter]::GetBytes($this.info       ) +
        [BitConverter]::GetBytes($this.addralign  ) +
        [BitConverter]::GetBytes($this.entsize    )
    }
  }

  $NecessarySectionNames = @(
    ""
    ".iopmod"
    ".text"
    ".rodata"
    ".data"
    ".sdata"
    ".sbss"
    ".bss"
    ".shstrtab"
    ".rel.text"
    ".rel.rodata"
    ".rel.data"
    ".rel.sdata"
  )
}

Process {
  trap {
    break
  }

  switch ($PSCmdlet.ParameterSetName) {
    'Path' {
      $InFilePath = @(Resolve-Path -Path $Path)[0].ToString()
      break
    }
    'LiteralPath' {
      $InFilePath = @(Resolve-Path -LiteralPath $LiteralPath)[0].ToString()
      break
    }
    Default {
      Write-Error -Message "Invalid parameter."
      return
    }
  }

  if ($PSVersionTable.PSVersion.Major -lt 6) {
    $ElfFile = Get-Content -LiteralPath $InFilePath -Raw -Encoding Byte
  }
  else {
    $ElfFile = Get-Content -LiteralPath $InFilePath -Raw -AsByteStream
  }

  $ElfHeader = [elf32_hdr]::new($ElfFile,0)

  $ProgramHeader = if (0 -ne $ElfHeader.phnum) {@((0..($ElfHeader.phnum-1)).ForEach{[elf32_phdr]::new($ElfFile,$ElfHeader.phoff + $_*$ElfHeader.phentsize)})}
  $SectionHeader = if (0 -ne $ElfHeader.shnum) {@((0..($ElfHeader.shnum-1)).ForEach{[elf32_shdr]::new($ElfFile,$ElfHeader.shoff + $_*$ElfHeader.shentsize)})}
  $ShstrOffset = $SectionHeader[$ElfHeader.shstrndx].offset

  $Sections = New-Object Collections.ArrayList
  foreach ($Header in $SectionHeader) {
    $Sections.Add([PSCustomObject]@{
      name = [Text.Encoding]::ASCII.GetString($ElfFile,$ShstrOffset+$Header.name,16).Split("`0")[0]
      header = $Header
      content = if ((8 -ne $Header.type) -and (0 -ne $Header.size)) { $ElfFile[$Header.offset..($Header.offset+$Header.size-1)] }
    }) > $null
  }

  $Sections         = $Sections | Where-Object {$_.name -in $NecessarySectionNames}
  $BodySections     = $Sections | Sort-Object {$_.header.offset} | Select-Object -Skip 2
  $IopmodSection    = $Sections | Where-Object {".iopmod" -eq $_.name}
  $TextSection      = $Sections | Where-Object {".text" -eq $_.name}
  $ShstrSection     = $Sections | Where-Object {".shstrtab" -eq $_.name}

  $ElfHeader.shstrndx = $Sections.IndexOf($ShstrSection)
  $ElfHeader.shnum    = $Sections.Count

  $LoadSections = $BodySections | Select-Object -First $BodySections.IndexOf($ShstrSection)
  $RelSections  = $BodySections | Select-Object -Skip ($BodySections.IndexOf($ShstrSection) + 1)

  $ShstrString = ($Sections.name -join "`0") + "`0"
  $ShstrSection.content = [Text.Encoding]::ASCII.GetBytes($ShstrString)
  foreach ($Section in $Sections) {
    $Section.header.name = $ShstrString.IndexOf($Section.name)
  }
  $ShstrSection.header.size = $ShstrSection.content.Count

  $CurOffset = [Text.Encoding]::ASCII.GetString($TextSection.content).IndexOf("cdvdman")
  if (0 -lt $CurOffset) {
    $TextSection.content[$CurOffset + 0] = [Convert]::ToByte([Char]"c")
    $TextSection.content[$CurOffset + 1] = [Convert]::ToByte([Char]"d")
    $TextSection.content[$CurOffset + 2] = [Convert]::ToByte([Char]"v")
    $TextSection.content[$CurOffset + 3] = [Convert]::ToByte([Char]"d")
    $TextSection.content[$CurOffset + 4] = [Convert]::ToByte([Char]"n")
    $TextSection.content[$CurOffset + 5] = [Convert]::ToByte([Char]"u")
    $TextSection.content[$CurOffset + 6] = [Convert]::ToByte([Char]"l")
  }

  $CurOffset = [Text.Encoding]::ASCII.GetString($TextSection.content).IndexOf("sifcmd")
  if (0 -lt $CurOffset) {
    $TextSection.content[$CurOffset + 0] = [Convert]::ToByte([Char]"f")
    $TextSection.content[$CurOffset + 1] = [Convert]::ToByte([Char]"a")
    $TextSection.content[$CurOffset + 2] = [Convert]::ToByte([Char]"k")
    $TextSection.content[$CurOffset + 3] = [Convert]::ToByte([Char]"e")
    $TextSection.content[$CurOffset + 4] = [Convert]::ToByte([Char]"s")
    $TextSection.content[$CurOffset + 5] = [Convert]::ToByte([Char]"i")
    $TextSection.content[$CurOffset + 6] = [Convert]::ToByte([Char]"f")
  }

  $CurOffset = $ProgramHeader[0].offset + $ProgramHeader[0].filesz
  $Padding1 = @([Byte]0) * ($ProgramHeader[1].offset - $CurOffset)
  $CurOffset = $ProgramHeader[1].offset

  foreach ($Section in $BodySections) {
    $Section.header.offset = $CurOffset
    if (8 -ne $Section.header.type) {
      $CurOffset += $Section.header.size
    }
    if (".shstrtab" -eq $Section.name) {
      $Padding2 = @([Byte]0) * ($CurOffset % 4)
      $CurOffset += $Padding2.Count
      $ElfHeader.shoff = $CurOffset
      $CurOffset += $ElfHeader.shentsize * $ElfHeader.shnum
    }
  }
  $SectionHeader = $Sections.header

  $ElfFile = @(
    $ElfHeader.GetBytes()
    $ProgramHeader.GetBytes()
    $IopmodSection.content
    $Padding1
    $LoadSections.content
    $ShstrSection.content
    $Padding2
    $SectionHeader.GetBytes()
    $RelSections.content
  )

  $OutFilePath = $InFilePath -replace "\.(?=\w+$)", "_linkfix."
  if ($PSVersionTable.PSVersion.Major -lt 6) {
    Set-Content -Value $ElfFile -LiteralPath $OutFilePath -Encoding Byte
  }
  else {
    Set-Content -Value $ElfFile -LiteralPath $OutFilePath -AsByteStream
  }
  return
}
