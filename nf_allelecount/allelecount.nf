nextflow.enable.dsl=2

process alleleCount {
  container 'docker://quay.io/wtsicgp/allelecount:v4.3.0'
  
  output:
  stdout emit: consout
  
  // alleleCounter returning SIGINT causes nextflow to hang (nextflow bug)
  // hence trap
  script:
  """
  trap 'exit 1' SIGINT  
  alleleCounter $params.opts -l $params.locipath -b $params.htspath -o $params.outpath 
  """
  
}

// output sent to stdout
workflow {
  alleleCount()
  alleleCount.out.consout.view()
}