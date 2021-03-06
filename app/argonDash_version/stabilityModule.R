stabilityUi <- function(id){
  ns <- NS(id)
  introBox(
    uiOutput(ns("info_eq"), width = 12),
    data.step = 4,
    data.intro = help_text[4]
  )
}


stability <- function(input, output, session, model_params, printInfos) {
  
  # find eauilibria
  equilibria <- reactive({
    
    req(!is.null(model_params()))
    
    A <- if (model_params()[['c']] >= 1) model_params()[['b']] * (model_params()[['c']] - 1) else NULL
    # check if sqrt makes sense from mathematical 
    # point of view
    if (!is.null(A)) A <- sqrt(A) else NULL
    B <- model_params()[['c']] - 1
    
    # return the number of eauilibria 
    # depending on A
    if (!is.null(A)) {
      list(
        eq1 = c(0, 0, 0),
        eq2 = c(A, A, B),
        eq3 = c(-A, -A, B)
      )
    } else {
      list(eq1 = c(0, 0, 0)) 
    }
  })
  
  # perform stability analysis
  # we need out()
  stability <- reactive({
    
    lapply(
      seq_along(equilibria()),
      FUN = function(i) {
        
        x_i <- equilibria()[[i]][1]
        y_i <- equilibria()[[i]][2]
        z_i <- equilibria()[[i]][3]
        
        jac <- matrix(
          c(-model_params()[['a']], model_params()[['a']], 0,
            model_params()[['c']] - z_i, -1, -x_i,
            y_i, x_i, -model_params()[['b']] 
          ),
          nrow = 3,
          byrow = TRUE
        )
        
        # routh hurwitz criterion
        a1 <- 1 + model_params()[['a']] + model_params()[['b']]
        a2 <- model_params()[['a']] + model_params()[['a']] * model_params()[['b']] + model_params()[['b']] - 
              model_params()[['a']] * model_params()[['c']] + x_i^2 + model_params()[['a']] * z_i
        a3 <- model_params()[['a']] * model_params()[['b']] * (1 - model_params()[['c']] + z_i) + 
              model_params()[['a']] * x_i * (x_i + y_i)
        
        # stability criterion
        res <- if (a1 > 0 && a1 * a2 > a3 && a3 > 0) "stable" else "unstable"
        return(list(res, jac))
      }
    )
    
  })
  
  # render info boxes for stability 
  output$info_eq <- renderUI({
    
    req(printInfos())
    
    fluidRow(
      lapply(seq_along(equilibria()), FUN = function(i){
        eq <- round(equilibria()[[i]])
        jac <- round(stability()[[i]][[2]])
        stability <- stability()[[i]][[1]]
        
        argonInfoCard(
          title =  HTML(paste0("(", eq[1], ", ", eq[2], ", ", eq[3], ")")),
          value = withMathJax(paste("$$
            \\begin{align}
            J^{\\ast} = 
            \\begin{pmatrix}
            ", jac[1], " & ", jac[2], " & ", jac[3], " \\\\
            ", jac[4], " & ", jac[5], " & ", jac[6], " \\\\
            ", jac[7], " & ", jac[8], " & ", jac[9], "
            \\end{pmatrix}
            \\end{align}$$")),
          description = stability,
          icon = "question-circle",
          width = 4,
          shadow = TRUE,
          hover_lift = TRUE,
          background_color = if (stability == "stable") "green" else "yellow"
        )
      })
    )
  })
}