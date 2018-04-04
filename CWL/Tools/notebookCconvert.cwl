cwlVersion: v1.0
class: CommandLineTool

label: ipython notebook converter
doc:  |
    Decompress gz input files with gzip
    
hints:
  DockerRequirement:
    # dockerPull: mgrast/amplicon:1.0
    dockerPull: cmdv/notebook:latest
    
  
stdout: $(inputs.notebook.nameroot).html    
stderr: notebook.error

baseCommand: [jupyter]
    
# requirements:
#   - class: InitialWorkDirRequirement
#     listing: $(inputs.directory.listing)
  
      
arguments:
  - nbconvert 
  - --execute
  - --stdout
    

inputs:
  notebook:
    type: File
    secondaryFiles: $(inputs.directory.listing)  
    inputBinding:
      position: 1
    format:
      - txt
  directory:
    type: Directory
    doc: top level directory containig all subdirectories and data referenced by the notebook, sibling of notebook file.  
  # files:
#     type: File[]?
#     secondaryFiles: $(inputs.directory.listing)
  
  # execute:
#     type: boolean
#     prefix: --execute
#     default: True


outputs: 
  html:
    type: stdout
  error: 
    type: stderr
  # html:
#     type: File?
#     format: html
#     outputBinding:
#       glob: $(inputs.notebook.nameroot).html
  