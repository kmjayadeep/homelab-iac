{
  pkgs,
  inputs,
  ...
}: {

  home.packages = with pkgs; [
    # Open task annoted items externally, eg: open urls in browser
    taskopen
    tasksh # for review
  ];

  # Enable taskwarrior
  programs.taskwarrior = {
    dataLocation = "~/private/psuite/todo";
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      context.work.read = "project:work";
      context.work.write = "project:work";

      context.nowork.read = "project.isnt:work";

      uda.priority.values = "H,L,";
      urgency.uda.priority.H.coefficient = "6.0";
      urgency.uda.priority.L.coefficient = "-6.0";

      # GTD reports config
      # report.next.columns = "id,start.age,priority,project,tags,recur,scheduled.countdown,due.relative,until.remaining,description.count,folder,urgency";
      # report.next.labels = "ID,Active,P,Project,Tag,Recur,S,Due,Until,Description,folder,Urg";
      # report.next.sort = "folder-/,urgency-";

      # Tasks added using `in`, no project specified
      "report.in.columns" = "id,description";
      "report.in.description" = "Inbox";
      "report.in.filter" = "project.none: status:pending";
      "report.in.labels" = "ID,Description";

      report.today.description = "Today's tasks";
      report.today.columns = "id,priority,project,tags,description.count,due.relative";
      report.today.labels = "ID,P,Project,Tag,Description,Due";
      # Show
      # -- All completed tasks for today, irrespective of schedule
      # -- Everything scheduled for today, which are not completed yet
      # -- All tasks in progress, irrespective of start date and other fields
      report.today.filter = "(end.after:today status:completed) or (scheduled.before:tomorrow status:pending) or (start.any: status.not:completed status.not:deleted)";
      report.today.sort = "status-/,due+,project+,scheduled+";

      report.backlog.description = "Tasks in backlog by project";
      report.backlog.columns = "id,priority,project,tags,scheduled,scheduled.relative,description.count,due.relative";
      report.backlog.labels = "ID,P,Project,Tag,Schedule,S,Description,Due";
      report.backlog.filter = "project.any: status:pending";
      report.backlog.sort = "project+/,scheduled+";

      # report.someday.columns = "id,description.count";
      # report.someday.description = "Someday/Maybe";
      # report.someday.filter = "limit: folder:someday status:pending";
      # report.someday.labels = "ID,Description";
    };
  };
}
