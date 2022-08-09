nextflow.enable.dsl=2

process alleleCount {
  container 'docker://quay.io/wtsicgp/allelecount:v4.3.0'
  
  output:
  stdout emit: consout
  
  script:
  """
  trap 'exit 1' SIGINT  # alleleCounter returning SIGINT causes nextflow to hang (nextflow bug) 
  alleleCounter $params.args
  """
  
}

workflow {
  alleleCount()
  alleleCount.out.consout.view()
}