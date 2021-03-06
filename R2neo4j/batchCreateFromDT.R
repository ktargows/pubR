## ---------------------------------------------------------------------------- #
##               THIS REQUIRES TWO DATA.TABLES (OR DATA.FRAMES)
## ---------------------------------------------------------------------------- #
##  NodesDT -  table of Nodes + properties
##  RelsDT  -  table of Edges + properties
##
##  The NodesDT should have a column named "node" which will 
##  serve as a (temporary!)* unique identifier for that node. 
##  
##  In the RelsDT table, the 'start' and 'end' values should
##  correspond to the 'node' value in NodesDT
##  
##  *why temporary:  This 'node' value is used only for importing. 
##                    and may be subject to change. 
##   Note that the NodesDT can have another column which is a proper node id. 
## ---------------------------------------------------------------------------- #

##  SAMPLE TABLES
#
#  NodesDT 
#
#         node   type             name        id sourceGrp
#        44154 artist   Theodis Easley ART044154     Concs
#         7553 artist Chelsea Williams ART007553     Concs
#        18414 artist      Howard Ghee ART018414     Concs
#        40392 artist    The Balconies ART040392     Concs
#        21770 artist    Junior League ART021770     Concs 
#
#      
#  RelsDT
#   (note that every value of start & end corresponds to a 'node' in NodesDT) 
#
#       start   end        type source concertID concertDate rel.id
#       21770 44154   played_at  Concs     18011  2002-01-25      1
#       21770 40392 played_with  Concs     86843  2006-08-29      2
#       21770  7553 played_with  Concs     30094  2003-05-24      3
#       40392 40392   played_at  Concs     58171  2004-11-13      4
#        7553 18414       is_in  Concs                            5
#       21770 40392 played_with  Concs     26415  2002-12-14      6
#       21770 21770   played_at  Concs    126718  2009-03-28      7
#       21770  7553   played_at  Concs     31761  2003-08-01      8
#        7553 40392   played_at  Concs    141813  2010-03-27      9
#        7553 21770   played_at  Concs    141799  2010-04-10     10
#       21770  7553 played_with  Concs     33195          NA     11
#        7553 40392   played_at  Concs    133523  2009-04-17     12
#
#
#
#
# --------------------------------------------------------------------------- #
#  If you'd like to expirement, you can recreate the data, using the following: 
#       
#   NodesDT <- structure(list(node = c(44154, 7553, 18414, 40392, 21770), type = c("artist", "artist", "artist", "artist", "artist"), name = c("Theodis Easley", "Chelsea Williams", "Howard Ghee", "The Balconies", "Junior League"), id = c("ART044154", "ART007553", "ART018414", "ART040392", "ART021770"), sourceGrp = c("Concs", "Concs", "Concs", "Concs", "Concs")), .Names = c("node", "type", "name", "id", "sourceGrp"), class = "data.frame", row.names = c(NA, -5L))
#   RelsDT  <- structure(list(start = c("21770", "21770", "21770", "40392", "7553", "21770", "21770", "7553", "21770", "7553"), end = c(44154, 40392, 7553, 40392, 18414, 40392, 21770, 21770, 7553, 40392),     type = c("played_at", "played_with", "played_with", "played_at",     "is_in", "played_with", "played_at", "played_at", "played_with",     "played_at"), source = c("Concs", "Concs", "Concs", "Concs",     "Concs", "Concs", "Concs", "Concs", "Concs", "Concs"), concertID = c("18011",     "86843", "30094", "58171", "", "26415", "126718", "141799",     "33195", "133523"), concertDate = c("2002-01-25", "2006-08-29",     "2003-05-24", "2004-11-13", "", "2002-12-14", "2009-03-28",     "2010-04-10", NA, "2009-04-17"), rel.id = c(1L, 2L, 3L, 4L,     5L, 6L, 7L, 10L, 11L, 12L)), .Names = c("start", "end", "type", "source", "concertID", "concertDate", "rel.id"), row.names = c(1L, 2L, 3L, 4L, 5L, 6L, 7L, 10L, 11L, 12L), class = "data.frame")
#    
# --------------------------------------------------------------------------- #


## EG: 
#  output <- batchCreateNodesAndRels(NODES.DT, RELS.DT, save.content.objs=TRUE)
#   OR turn on Stream ing for troubleshooting
#  output <- batchCreateNodesAndRels(NODES.DT, RELS.DT, stream=TRUE, save.content.objs=TRUE)


                                                        # these other arguments are less important right now. 
batchCreateNodesAndRels <- function(NodesDT, RelsDT,  nodes.idcol="node", addSerialNumberToRels=TRUE, verbose=TRUE, stream=FALSE, save.content.objs=FALSE, save.output.to.global=TRUE) { 
# TODO:  Explore passing the name of the DT. Will this save efficiency (memory or time)?


  if (addSerialNumberToRels && is.data.table(RelsDT)) { 
    maxNode <- max(NodesDT$node)
    # round up to the next power of ten
    starting.serial <- 10 ^ ceiling(log(maxNode, 10))
    RelsDT[, rel.id := (1:.N) + starting.serial]
  }

  # Creating these two objects (Specifically content.rels) is very costly.  Thus, once complete, save to memory (outside this function) if user flagged this option. 
  #  Also, if flag is on, check first if object exists. 
  if (save.content.objs) {
  
    # Check if it exists already, if so load it. If not, create it, then save it. 
    if (exists("content.nodes", envir=.GlobalEnv)) {
      content.nodes <- get("content.nodes", envir=.GlobalEnv)
    } else{
      content.nodes <- batchMethodsForNodes(NodesDT, idcol=nodes.idcol, verbose=verbose)
      assign("content.nodes", content.nodes, envir=.GlobalEnv)
      if (verbose)
        cat("Saved `content.nodes` to .GlobalEnv")
    }

    # Check if it exists already, if so load it. If not, create it, then save it. 
    if (exists("content.rels", envir=.GlobalEnv)) {
      content.rels <- get("content.rels", envir=.GlobalEnv)
    } else{
      content.rels <- batchMethodsForRels(RelsDT, verbose=verbose)
      assign("content.rels", content.rels, envir=.GlobalEnv)
      if (verbose)
        cat("Saved `content.rels` to .GlobalEnv")
    }
  
  # If user did not flag to save, then just create as normal.  [Note, these are the only two lines that are actually needed, except for the extra lines for backup and recovery]  
  }  else {
    content.nodes <- batchMethodsForNodes(NodesDT, idcol=nodes.idcol, verbose=verbose)
    content.rels  <- batchMethodsForRels(RelsDT, verbose=verbose)
  }


  # verbose output for troubleshooting
  if (verbose) {
    cat(rep("#", 55), sep="")
    cat("\n\t\tFirst 10 JSON contents for nodes: \n", "   ", rep("-", 45), "\n", sep="")
    print(head(content.nodes, 10))
    cat("\n\t\tFirst 10 JSON contents for rels: \n", "   ", rep("-", 45), "\n", sep="")
    print(head(content.nodes, 10))
    cat(rep("#", 55), sep="")
  }


  # note:  collapse if c(..), else use sep
  content <- paste0("[", paste(c(content.nodes, content.rels), collapse=", "), "]" )

  streaming <- setNames(ifelse(stream, streamOn, streamOff), "X-Stream")

  H.post  <- getURL(u.batch, httpheader = c(jsonHeader, streamOn), postfields = content)

  # incase user forgot to assign the output to an object, we dont want the handle to just dissappear. 
  if (save.output.to.global) {
    saveTo <- paste0("LastBatchCreate.", what)
    assign(saveTo, H.post, envir=.GlobalEnv)
    cat("Neo4j response saved to\n  `", saveTo, "`\n", sep="")
  }

  return(H.post)

}



batchMethodsForNodes <- function(DT, idcol="node", verbose=FALSE) {
## TODO: have a sepearte method for data.frame / data.table.  Different syntax
## TODO:  Error check the arguments and whats expected

  # allows for names of the DT to be passed instead of the whole object
  if (is.character(DT))
    DT <- get(DT)

  if (verbose)
    cat("\nCreating Nodes 'content'. \n")


  # confirm idcol is in the names of DT. 
  if(any(idcol==names(DT))) {
      useID <- TRUE
      idcol.idx <- which(idcol==names(DT))
  } else {
     stop("Couldn't find idcol, '", idcol, "' amongst the names of DT")
  }

  # return
  apply(DT, 1, function(x) 
            toJSON(list(method="POST", to="/node", 
               body=as.list(x[-idcol.idx]), id=as.numeric(x[idcol.idx])  ))   )
}


batchMethodsForRels <- function(DT, verbose=FALSE)  {

  # allows for names of the DT to be passed instead of the whole object
  if (is.character(DT))
    DT <- get(DT)

  if (verbose)
    cat("\nCreating Rels 'content'. \n")


  dataCols <- setdiff(names(DT), c("start", "end", "rel.id", "type"))

  contentForBatch <- function(x, dataCols) {
  # applying to each row of x
  toJSON(list(
    method = "POST" , 
    to =  paste0("{", as.integer(x[["start"]]),  "}/relationships") , 
    id =  as.integer(x[["rel.id"]] ), 
    body = list(
      to = paste0("{", as.integer(x[["end"]]),  "}"),
      data = x[dataCols], 
      type = x[["type"]]
      )
    ))
  }

  # return
  apply(DT, 1, contentForBatch, dataCols)
}


#  # if it fails, the whole thing fails, thus lets break it down. 
#  chopUpDTNodesAndRels <- function(NodesDT, RelsDT, howManyChops=10, nodes.idcol="node") {
#  
#    rowsPerChop <- ceiling(nrow(NodesDT) / howManyChops)
#    chopGroup   <- rep(seq(howManyChops), each=rowsPerChop) [1:nrow(NodesDT)]
#  
#    NodesDT[, .chopGrp := chopGroup]
#    NodesDT.list <- lapply(seq(howManyChops), function(i) NodesDT[.chopGrp==i, .SD, .SDcols=setdiff(names(NodesDT), ".chopGrp")])
#  
#    # lapply(NodesDT.list, RelsDT[....   <FAIL> one node can relte to multiple parts in the table ] )
#    #                               < we can ensure that ther eare no rows from RelsDT that dont 
#  
#    return("You shouldnt use this function. It doesnt make sense.")
#  }



